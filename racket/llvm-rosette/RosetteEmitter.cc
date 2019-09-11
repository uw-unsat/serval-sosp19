#include <llvm/ADT/StringSet.h>
#include <llvm/Analysis/PostDominators.h>
#include <llvm/IR/CFG.h>
#include <llvm/IR/DebugInfoMetadata.h>
#include <llvm/IR/GetElementPtrTypeIterator.h>
#include <llvm/IR/InlineAsm.h>
#include <llvm/IR/InstIterator.h>
#include <llvm/IR/InstVisitor.h>
#include <llvm/Support/FileSystem.h>
#include <llvm/Support/Format.h>
#include <llvm/Support/Regex.h>
#include <llvm/Support/raw_ostream.h>
#include <regex>
#include "RosetteEmitter.h"

#ifdef assert
#undef assert
#endif

#define assert(cond) do {                                           \
    if (!(cond))                                                    \
        llvm::llvm_unreachable_internal(#cond, __FILE__, __LINE__); \
} while (0)

static std::string getName(llvm::Value *V)
{
    std::string s;
    llvm::raw_string_ostream OS(s);

    assert(V);
    V->printAsOperand(OS, false);

    return OS.str();
}

std::string getName(llvm::Value &V)
{
    return getName(&V);
}

std::string getType(llvm::Type *T)
{
    std::string s;
    llvm::raw_string_ostream OS(s);

    assert(T);

    /* TODO: define struct-type/vector-type rather than using Racket list/vector. */

    if (T->isIntegerTy()) {
        OS << "(bitvector " << T->getIntegerBitWidth() << ")";
    } else if (auto ST = llvm::dyn_cast<llvm::StructType>(T)) {
        /* We should never print out struct type names. */
        assert(ST->isLiteral());
        /* LLVM prints { ... } for literal struct types; change to (list ...). */
        OS << "(list";
        for (auto ET : ST->elements())
            OS << " " << getType(ET);
        OS << ")";
    } else if (auto VT = llvm::dyn_cast<llvm::VectorType>(T)) {
        /* We don't really support vector types, just to avoid syntax errors. */
        OS << "(make-vector " << VT->getNumElements()
           << " " << getType(VT->getElementType()) << ")";
    } else {
        /* unsupported type */
        OS << '"' << *T << '"';
    }

    return OS.str();
}

static void printRacketEscaped(llvm::StringRef S, llvm::raw_ostream &OS)
{
    OS << "#\"";
    /* ignore trailing null */
    if (!S.empty() && !S.back())
        S = S.substr(0, S.size() - 1);
    for (auto c : S) {
        if (llvm::isPrint(c) && c != '\\' && c != '"')
            OS << c;
        else
            OS << "\\x" << llvm::hexdigit(c / 16) << llvm::hexdigit(c % 16);
    }
    OS << "\"";
}

static bool isBuiltinFunction(llvm::Function *F) {
    static llvm::Regex re(
        "(llvm\\.bswap\\.i(16|32|64))|"
        "(llvm\\.[su](add|sub|mul)\\.with\\.overflow\\.i(16|32|64))|"
        "(llvm\\.lifetime\\.(start|end)\\.p0i8)|"
        "(llvm\\.memset\\.p0i8\\.i64)|"
        "(memset|memzero_explicit)"
    );
    return re.match(F->getName());
}

static bool isUBSanFunction(llvm::Function *F) {
    return F->getName().startswith("__ubsan_handle_");
}

static bool isAssertFunction(llvm::Function *F) {
    static llvm::StringSet<> lifts = {
        "__assert_fail", "__assert_func", "__assert_rtn",
    };
    return lifts.count(F->getName());
}

static bool isDbgFunction(llvm::Function *F) {
    switch (F->getIntrinsicID()) {
    case llvm::Intrinsic::dbg_addr:
    case llvm::Intrinsic::dbg_declare:
    case llvm::Intrinsic::dbg_label:
    case llvm::Intrinsic::dbg_value:
        return true;
    default:
        break;
    }

    return false;
}

struct InstVisitor : llvm::InstVisitor<InstVisitor> {
    InstVisitor(const llvm::DataLayout &DL, llvm::raw_ostream &OS)
        : DL(DL), OS(OS) {}

    // fake a return value to simplify the use
    llvm::StringRef getRef(llvm::Value *V) {
        assert(V);
        auto T = V->getType();

        if (llvm::isa<llvm::ConstantAggregateZero>(V)) {
            OS << "(zeroinitializer " << getType(T) << ")";
        } else if (llvm::ConstantInt *CI = llvm::dyn_cast<llvm::ConstantInt>(V)) {
            OS << "(bv " << CI->getValue() << " " << CI->getBitWidth() << ")";
        } else if (llvm::isa<llvm::ConstantExpr>(V)) {
            visitOperator(*llvm::cast<llvm::Operator>(V));
        } else if (llvm::isa<llvm::UndefValue>(V)) {
            OS << "(undef " << getType(T) << ")";
        } else if (llvm::isa<llvm::ConstantVector>(V) || llvm::isa<llvm::ConstantDataVector>(V)) {
            auto CV = llvm::cast<llvm::Constant>(V);
            OS << "(vector";
            for (unsigned i = 0, n = CV->getNumOperands(); i != n; ++i)
                OS << " " << getRef(CV->getOperand(i));
            OS << ")";
        } else {
            V->printAsOperand(OS, false);
        }
        return llvm::StringRef();
    }

    void visitOperator(llvm::Operator &O) {
        unsigned opcode = O.getOpcode();

        if (llvm::GEPOperator *GEP = llvm::dyn_cast<llvm::GEPOperator>(&O))
            return visitGEPOperator(*GEP);

        OS << "(" << llvm::Instruction::getOpcodeName(O.getOpcode());

        if (llvm::CmpInst *CI = llvm::dyn_cast<llvm::CmpInst>(&O))
            OS << "/" << llvm::CmpInst::getPredicateName(CI->getPredicate());

        for (unsigned i = 0, n = O.getNumOperands(); i != n; ++i)
            OS << " " << getRef(O.getOperand(i));

        /* emit type for cast instructions & expressions (except for bitcast/inttoptr) */
        if (llvm::Instruction::isCast(opcode) && opcode != llvm::Instruction::BitCast
                                              && opcode != llvm::Instruction::IntToPtr)
            OS << " " << getType(O.getType());

        if (llvm::LoadInst *LI = llvm::dyn_cast<llvm::LoadInst>(&O)) {
            llvm::Type *T = LI->getType();
            if (T->isPointerTy())
                OS << " (bitvector 64) #:pointer #t";
            else
                OS << " " << getType(T);
            OS << " #:align " << LI->getAlignment();
        }
        if (llvm::StoreInst *SI = llvm::dyn_cast<llvm::StoreInst>(&O)) {
            llvm::Type *T = SI->getValueOperand()->getType();
            if (T->isPointerTy())
                OS << " (bitvector 64) #:pointer #t";
            else
                OS << " " << getType(T);
            OS << " #:align " << SI->getAlignment();
        }

        /* emit indices for extractvalue/insertvalue */
        if (auto EVI = llvm::dyn_cast<llvm::ExtractValueInst>(&O)) {
            for (auto idx : EVI->indices())
                OS << " " << idx;
        }
        if (auto IVI = llvm::dyn_cast<llvm::InsertValueInst>(&O)) {
            for (auto idx : IVI->indices())
                OS << " " << idx;
        }

        OS << ")";
    }

    void visitGEPOperator(llvm::GEPOperator &GEP) {
        // add size to each index
        OS << "(" << llvm::Instruction::getOpcodeName(GEP.getOpcode())
           << " " << getRef(GEP.getPointerOperand());

        for (auto GTI = gep_type_begin(GEP), GTE = gep_type_end(GEP); GTI != GTE; ++GTI) {
            auto V = GTI.getOperand();
            OS << " (";
            if (auto ST = GTI.getStructTypeOrNull()) {
                auto CI = llvm::dyn_cast<llvm::ConstantInt>(V);
                assert(CI);
                auto idx = CI->getZExtValue();
                auto offset = DL.getStructLayout(ST)->getElementOffset(idx);
                OS << "struct-offset " << offset;
            } else {
                auto size = DL.getTypeAllocSize(GTI.getIndexedType());
                OS << "array-offset " << getRef(V) << " " << size;
            }
            OS << ")";
        }

        OS << ")";
    }

    void visitInstruction(llvm::Instruction &I) {
        bool isVoid = I.getType()->isVoidTy();

        if (!isVoid)
            OS << "(set! " << getName(I) << " ";

        visitOperator(llvm::cast<llvm::Operator>(I));

        if (!isVoid)
            OS << ")";
    }

    void visitPHINode(llvm::PHINode &I) {
        unsigned i, n;

        OS << "(set! " << getName(I) << " (phi";
        for (i = 0, n = I.getNumIncomingValues(); i != n; ++i)
            OS << " ["
               << getRef(I.getIncomingValue(i)) << " "
               << getRef(I.getIncomingBlock(i)) << "]";
        OS << "))";
    }

    void visitBranchInst(llvm::BranchInst &I) {
        // swizzle the branches
        OS << "(br ";
        if (I.isUnconditional())
            OS << getRef(I.getSuccessor(0));
        else
            OS << getRef(I.getCondition()) << " "
               << getRef(I.getSuccessor(0)) << " "
               << getRef(I.getSuccessor(1));
        OS << ")";
    }

    void emitInlineAsm(llvm::InlineAsm *Asm) {
        /* match one-liners for inline asm */
        const std::string &s = Asm->getAsmString();
        std::smatch m;

        OS << "asm ";

        if (s.empty()) {
            OS << "'nop";
        } else if (std::regex_match(s, m, std::regex("[^\\s]+"))) {
            /* with no parameters: "sfence.vma" */
            OS << "'" << s;
        } else if (std::regex_match(s, m, std::regex("([^\\s]+)\\s+\\$0,\\s*([^\\s,]+)"))) {
            /* read a value: "csrr $0, pmpcfg0" */
            OS << "'" << m[1] << " '" << m[2];
        } else if (std::regex_match(s, m, std::regex("([^\\s]+)\\s+([^\\s,]+),\\s*\\$0"))) {
            /* write a value: "csrw pmpaddr0, $0" */
            OS << "'" << m[1] << " '" << m[2];
        } else {
            /* no match */
            OS << '"' << s << '"';
        }
    }

    void emitLiftValue(llvm::Value *V) {
        // recursively lift initializer
        if (auto GV = llvm::dyn_cast<llvm::GlobalVariable>(V->stripPointerCasts())) {
            if (GV->hasInitializer()) {
                emitLiftValue(GV->getInitializer()->stripPointerCasts());
                return;
            }
        }

        // lift LLVM integers to Racket integers
        if (auto CI = llvm::dyn_cast<llvm::ConstantInt>(V)) {
            OS << CI->getValue();
            return;
        }

        // lift strings
        if (auto CDS = llvm::dyn_cast<llvm::ConstantDataSequential>(V)) {
            if (CDS->isString()) {
                printRacketEscaped(CDS->getAsString(), OS);
                return;
            }
        }

        // lift arrays/structs
        if (auto CA = llvm::dyn_cast<llvm::ConstantAggregate>(V)) {
            OS << "(list";
            for (auto I = CA->op_begin(), E = CA->op_end(); I != E; ++I) {
                OS << " ";
                emitLiftValue(*I);
            }
            OS << ")";
            return;
        }

        // no lifting
        OS << getRef(V);
    }

    void emitUBSan(llvm::CallInst &I) {
        assert(I.getNumArgOperands() > 0);
        llvm::Function *F = I.getCalledFunction();
        assert(F);
        OS << "(" << F->getName() << " ";
        // the first arg is data
        emitLiftValue(I.getArgOperand(0));
        // the rest are ValueHandle
        for (unsigned i = 1, n = I.getNumArgOperands(); i != n; ++i) {
            llvm::Value *V = I.getArgOperand(i);
            OS << " " << getRef(V);
        }
        OS << ")";
    }

    void emitAssert(llvm::CallInst &I) {
        llvm::Function *F = I.getCalledFunction();
        assert(F);
        OS << "(" << F->getName() << " ";
        // the rest are ValueHandle
        for (unsigned i = 0, n = I.getNumArgOperands(); i != n; ++i) {
            llvm::Value *V = I.getArgOperand(i);
            OS << " ";
            emitLiftValue(V);
        }
        OS << ")";
    }

    void visitCallInst(llvm::CallInst &I) {
        bool isVoid = I.getType()->isVoidTy();
        llvm::InlineAsm *Asm = llvm::dyn_cast<llvm::InlineAsm>(I.getCalledValue());
        llvm::Function *CF = I.getCalledFunction();

        if (CF && CF->hasExternalLinkage()) {
            if (isUBSanFunction(CF)) {
                emitUBSan(I);
                return;
            }
            if (isAssertFunction(CF)) {
                emitAssert(I);
                return;
            }
        }

        if (!isVoid)
            OS << "(set! " << getName(I) << " ";

        OS << "(";
        if (CF && isBuiltinFunction(CF)) {
            /* promote to a first-class "instruction" */
            OS << CF->getName();
        } else if (Asm) {
            /* parse inline assembly */
            emitInlineAsm(Asm);
        } else {
            /* regular call */
            OS << I.getOpcodeName() << " " << getRef(I.getCalledValue());
        }

        for (unsigned i = 0, n = I.getNumArgOperands(); i != n; ++i) {
            llvm::Value *V = I.getArgOperand(i);
            OS << " " << getRef(V);
        }
        OS << ")";
        if (!isVoid)
            OS << ")";
    }

    void visitAllocaInst(llvm::AllocaInst &I) {
        OS << "(set! " << getName(I)
           << " (" << I.getOpcodeName() << " ";
        RosetteEmitter::emitGlobalType(OS, DL, I.getAllocatedType(), nullptr);
        OS << " #:align " << I.getAlignment() << "))";
    }

    void visitSwitchInst(llvm::SwitchInst &I) {
        OS << "(" << I.getOpcodeName()
           << " " << getRef(I.getCondition())
           << " " << getRef(I.getDefaultDest());

        for (auto Case : I.cases()) {
            OS << " [" << getRef(Case.getCaseValue())
               << " " << getRef(Case.getCaseSuccessor()) << "]";
        }

        OS << ")";
    }

private:
    const llvm::DataLayout &DL;
    llvm::raw_ostream &OS;
};

struct ValueVisitor : llvm::InstVisitor<ValueVisitor> {
    ValueVisitor(llvm::raw_ostream &OS) : OS(OS) {}

    void visitInstruction(llvm::Instruction &I) {
        if (I.getType()->isVoidTy())
            return;

        OS << "\n  (define-value " << getName(I) << ")";
    }

private:
    llvm::raw_ostream &OS;
};

void RosetteEmitter::emitPrelude(void)
{
    OS << "; DO NOT MODIFY.\n;\n"
          "; This file was automatically generated.\n\n"
          "#lang rosette\n\n"
          "(provide (all-defined-out))\n\n";
}

void RosetteEmitter::emitModule(llvm::Module &M)
{
    MST.reset(new llvm::ModuleSlotTracker(&M));

    llvm::SmallString<128> core("serval/lib/core");
    llvm::SmallString<128> llvm("serval/llvm");
    llvm::SmallString<128> ubsan("serval/ubsan");

    OS << "(require " << core << "\n"
          "         " << llvm << "\n"
          "         " << ubsan << ")\n\n";

    auto &DL = M.getDataLayout();
    OS << "(target-endian '" << (DL.isBigEndian() ? "big" : "little") << ")\n"
       << "(target-pointer-bitwidth " << DL.getPointerSizeInBits(0) << ")\n";

    for (auto &GV : M.getGlobalList())
        emitGlobalVariable(GV);

    if (!M.global_empty())
        OS << "\n";

    for (auto &F : M.getFunctionList())
        emitFunction(F);

    OS << "\n";
}

void RosetteEmitter::emitGlobals(llvm::Module &M)
{
    auto &DL = M.getDataLayout();

    OS << "(require serval/core)\n\n"
          "(define globals (make-hash (list";

    for (auto &GV : M.getGlobalList()) {
        llvm::DIType *DT = nullptr;
        llvm::SmallVector<llvm::DIGlobalVariableExpression *, 1> DGVEs;
        std::string name = getName(GV);

        assert(name[0] == '@');
        name = name.substr(1);

        GV.getDebugInfo(DGVEs);
        if (DGVEs.size() == 1)
            DT = DGVEs[0]->getVariable()->getType().resolve();

        OS << "\n  (cons '" << name << " (lambda () ";
        emitGlobalType(DL, GV.getValueType(), DT);
        OS << "))";
    }

    OS << ")))\n";
}

void RosetteEmitter::emitSymbols(llvm::Module &M)
{
    auto &DL = M.getDataLayout();
    uintptr_t addr = 0x80000000;

    for (auto &GV : M.getGlobalList()) {
        unsigned size = DL.getTypeAllocSize(GV.getValueType());
        unsigned align = DL.getPreferredAlignment(&GV);

        addr = llvm::alignTo(addr, align);
        OS << llvm::format_hex_no_prefix(addr, 16) << " "
           << llvm::format_hex_no_prefix(size, 16) << " B "
           << GV.getName() << "\n";
        addr += size;
    }
}

void RosetteEmitter::emitGlobalVariable(llvm::GlobalVariable &GV)
{
    OS << "\n(define-global " << getName(GV) << ")";
}

static llvm::DIType *stripDITypedef(llvm::DIType *DT)
{
    if (!DT || DT->getTag() != llvm::dwarf::DW_TAG_typedef)
        return DT;
    assert(llvm::isa<llvm::DIDerivedType>(DT));
    DT = llvm::cast<llvm::DIDerivedType>(DT)->getBaseType().resolve();
    return stripDITypedef(DT);
}

void RosetteEmitter::emitGlobalType(const llvm::DataLayout &DL, llvm::Type *T, llvm::DIType *DT, size_t idx)
{
    emitGlobalType(OS, DL, T, DT, idx);
}

void RosetteEmitter::emitGlobalType(llvm::raw_ostream &OS, const llvm::DataLayout &DL, llvm::Type *T, llvm::DIType *DT, size_t idx)
{
    DT = stripDITypedef(DT);
    unsigned size = DL.getTypeAllocSize(T);

    if (auto AT = llvm::dyn_cast<llvm::ArrayType>(T)) {
        auto ET = AT->getArrayElementType();
        auto esize = DL.getTypeAllocSize(ET);
        assert(size == esize * AT->getArrayNumElements());
        OS << "(marray " << AT->getArrayNumElements() << " ";
        if (DT) {
            /*
             * For arrays, the debugging information records the base type
             * and a list of the sizes of each dimension.  This is different
             * from the LLVM type system, which tracks each subtype.  Use an
             * index to track which dimension we are dealing with, and move
             * to the base type once we finish iterating.
             */
            assert(DT->getTag() == llvm::dwarf::DW_TAG_array_type);
            assert(llvm::isa<llvm::DICompositeType>(DT));
            ++idx;
            if (idx == llvm::cast<llvm::DICompositeType>(DT)->getElements().size()) {
                DT = llvm::cast<llvm::DICompositeType>(DT)->getBaseType().resolve();
                idx = 0;
            }
        }
        emitGlobalType(OS, DL, ET, DT, idx);
        OS << ")";
        return;
    }

    if (auto ST = llvm::dyn_cast<llvm::StructType>(T)) {
        auto SL = DL.getStructLayout(ST);
        llvm::DINodeArray Elements;
        if (DT) {
            assert(DT->getTag() == llvm::dwarf::DW_TAG_structure_type);
            assert(llvm::isa<llvm::DICompositeType>(DT));
            Elements = llvm::cast<llvm::DICompositeType>(DT)->getElements();
            assert(Elements.size() == ST->getNumElements());
        }
        OS << "(mstruct " << size << " (list";
        for (unsigned i = 0, n = ST->getNumElements(); i != n; ++i) {
            DT = (Elements.empty()) ? nullptr : llvm::dyn_cast<llvm::DIType>(Elements[i]);
            OS << " (mfield '";
            // extract struct field names from debugging information
            if (DT)
                OS << DT->getName();
            else
                OS << i;
            OS << " " << SL->getElementOffset(i) << " ";
            auto ET = ST->getElementType(i);
            if (DT) {
                assert(DT->getTag() == llvm::dwarf::DW_TAG_member);
                assert(llvm::isa<llvm::DIDerivedType>(DT));
                DT = llvm::cast<llvm::DIDerivedType>(DT)->getBaseType().resolve();
            }
            emitGlobalType(OS, DL, ET, DT);
            OS << ")";
        }
        OS << "))";
        return;
    }

    assert(T->isIntegerTy() || T->isPointerTy());
    OS << "(mcell " << size << ")";
}

void RosetteEmitter::emitFunction(llvm::Function &F)
{
    // skip special functions
    if (F.hasExternalLinkage()) {
        if (isBuiltinFunction(&F) || isDbgFunction(&F) ||
            isUBSanFunction(&F) || isAssertFunction(&F))
            return;
    }

    OS << "\n; @" << F.getName() << ": " << *F.getFunctionType() << "\n";

    llvm::PostDominatorTree domtree;
    domtree.recalculate(F);

    OS << "(define-function (@" << F.getName();
    for (auto &A : F.args())
        OS << " [" << getName(A) << " : " << getType(A.getType()) << "]";
    OS << ")";

    if (F.isDeclaration()) {
        OS << " (unreachable))\n";
        return;
    }

    for (llvm::BasicBlock &BB : F)
        emitBasicBlock(BB, domtree);

    // entry block
    OS << "\n; entry";
    ValueVisitor VV(OS);
    VV.visit(F);
    OS << "\n  (enter! " << getName(F.getEntryBlock()) << "))\n";
}

void RosetteEmitter::emitBasicBlock(llvm::BasicBlock &BB, const llvm::PostDominatorTree &domtree)
{
    OS << "\n" << llvm::left_justify( "; " + getName(BB), 50) << "; preds =";
    for (llvm::BasicBlock *pred : llvm::predecessors(&BB))
        OS << " " << getName(pred);

    std::string merge = "#f";
    const llvm::BranchInst *terminator = llvm::dyn_cast<llvm::BranchInst>(BB.getTerminator());
    if (terminator && terminator->isConditional()) {
        llvm::BasicBlock *common =
            domtree.findNearestCommonDominator(terminator->getSuccessor(0), terminator->getSuccessor(1));
        if (common != nullptr)
            merge = getName(common);
    }

    OS << "\n  (define-label (" << getName(BB) << ")" << " #:merge " << merge;

    InstVisitor IV(BB.getModule()->getDataLayout(), OS);
    for (llvm::Instruction &I : BB) {
        if (llvm::isa<llvm::DbgInfoIntrinsic>(I))
            continue;
        // print original LLVM instruction
        {
            // some instructions span multiple lines
            // therefore printing to a buffer
            std::string s;
            llvm::raw_string_ostream SOS(s);
            I.print(SOS, *MST, true);
            llvm::SmallVector<llvm::StringRef, 4> lines;
            llvm::StringRef(SOS.str()).split(lines, '\n');
            for (auto line : lines)
                OS << "\n; " << line;
        }
        OS << "\n    ";
        IV.visit(I);
    }
    OS << ")\n";
}
