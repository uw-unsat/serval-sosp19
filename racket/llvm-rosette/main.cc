#include <llvm/IR/Module.h>
#include <llvm/IRReader/IRReader.h>
#include <llvm/Support/CommandLine.h>
#include <llvm/Support/SourceMgr.h>
#include <llvm/Support/raw_ostream.h>
#include "RosetteEmitter.h"

namespace cl = llvm::cl;

static cl::opt<bool> global("globals", cl::desc("dump globals"));
static cl::opt<bool> symbols("symbols", cl::desc("fake a symbol map"));
static cl::opt<std::string> Input(cl::Positional, cl::desc("<input file>"), cl::init("-"));
static cl::list<std::string> functions("function", cl::desc("specify functions to analyze"));

int main(int argc, char **argv)
{
    llvm::LLVMContext ctx;
    llvm::SMDiagnostic err;
    RosetteEmitter re(llvm::outs());

    cl::ParseCommandLineOptions(argc, argv);
    auto M = llvm::parseIRFile(Input, err, ctx);

    if (!functions.empty()) {
        // delete unreferenced functions
        while (1) {
            bool changed = false;
            for (auto I = M->begin(), E = M->end(); I != E; ) {
                llvm::Function *F = &*I++;
                if (F->isDeclaration() || !F->use_empty())
                    continue;
                if (std::find(functions.begin(), functions.end(), F->getName()) != functions.end())
                    continue;
                F->eraseFromParent();
                changed = true;
            }
            if (!changed)
                break;
        }
    }

    if (symbols) {
        re.emitSymbols(*M);
        return 0;
    }

    re.emitPrelude();
    if (global)
        re.emitGlobals(*M);
    else
        re.emitModule(*M);
    return 0;
}
