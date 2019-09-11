#pragma once

#include <llvm/Analysis/PostDominators.h>
#include <llvm/IR/ModuleSlotTracker.h>
#include <map>
#include <memory>

namespace llvm {
class BasicBlock;
class DIType;
class Function;
class GlobalVariable;
class MDNode;
class Module;
class raw_ostream;
} // namespace llvm

typedef std::map<int, llvm::MDNode *> MDNodeMapT;

class RosetteEmitter {
public:
    RosetteEmitter(llvm::raw_ostream &OS) : OS(OS) {}
    void emitPrelude(void);
    void emitModule(llvm::Module &M);
    void emitGlobals(llvm::Module &M);
    void emitSymbols(llvm::Module &M);

    static void emitGlobalType(llvm::raw_ostream &OS, const llvm::DataLayout &DL, llvm::Type *T, llvm::DIType *DT, size_t idx = 0);

private:
    void emitGlobalVariable(llvm::GlobalVariable &GV);
    void emitGlobalType(const llvm::DataLayout &DL, llvm::Type *T, llvm::DIType *DT, size_t idx = 0);
    void emitFunction(llvm::Function &F);
    void emitBasicBlock(llvm::BasicBlock &BB, const llvm::PostDominatorTree &domtree);

    llvm::raw_ostream &OS;
    std::unique_ptr<llvm::ModuleSlotTracker> MST;
};
