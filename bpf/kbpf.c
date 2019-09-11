#include "filter.h"

/* Registers */
#define BPF_R0  regs[BPF_REG_0]
#define BPF_R1  regs[BPF_REG_1]
#define BPF_R2  regs[BPF_REG_2]
#define BPF_R3  regs[BPF_REG_3]
#define BPF_R4  regs[BPF_REG_4]
#define BPF_R5  regs[BPF_REG_5]
#define BPF_R6  regs[BPF_REG_6]
#define BPF_R7  regs[BPF_REG_7]
#define BPF_R8  regs[BPF_REG_8]
#define BPF_R9  regs[BPF_REG_9]
#define BPF_R10 regs[BPF_REG_10]

/* Named registers */
#define DST     regs[insn->dst_reg]
#define SRC     regs[insn->src_reg]
#define FP      regs[BPF_REG_FP]
#define AX      regs[BPF_REG_AX]
#define ARG1    regs[BPF_REG_ARG1]
#define CTX     regs[BPF_REG_CTX]
#define IMM     insn->imm

/* All UAPI available opcodes. */
#define BPF_INSN_MAP(INSN_2, INSN_3)            \
        /* 32 bit ALU operations. */            \
        /*   Register based. */                 \
        INSN_3(ALU, ADD,  X)                    \
        INSN_3(ALU, SUB,  X)                    \
        INSN_3(ALU, AND,  X)                    \
        INSN_3(ALU, OR,   X)                    \
        INSN_3(ALU, LSH,  X)                    \
        INSN_3(ALU, RSH,  X)                    \
        INSN_3(ALU, XOR,  X)                    \
        INSN_3(ALU, MUL,  X)                    \
        INSN_3(ALU, MOV,  X)                    \
        INSN_3(ALU, ARSH, X)                    \
        INSN_3(ALU, DIV,  X)                    \
        INSN_3(ALU, MOD,  X)                    \
        INSN_2(ALU, NEG)                        \
        INSN_3(ALU, END, TO_BE)                 \
        INSN_3(ALU, END, TO_LE)                 \
        /*   Immediate based. */                \
        INSN_3(ALU, ADD,  K)                    \
        INSN_3(ALU, SUB,  K)                    \
        INSN_3(ALU, AND,  K)                    \
        INSN_3(ALU, OR,   K)                    \
        INSN_3(ALU, LSH,  K)                    \
        INSN_3(ALU, RSH,  K)                    \
        INSN_3(ALU, XOR,  K)                    \
        INSN_3(ALU, MUL,  K)                    \
        INSN_3(ALU, MOV,  K)                    \
        INSN_3(ALU, ARSH, K)                    \
        INSN_3(ALU, DIV,  K)                    \
        INSN_3(ALU, MOD,  K)                    \
        /* 64 bit ALU operations. */            \
        /*   Register based. */                 \
        INSN_3(ALU64, ADD,  X)                  \
        INSN_3(ALU64, SUB,  X)                  \
        INSN_3(ALU64, AND,  X)                  \
        INSN_3(ALU64, OR,   X)                  \
        INSN_3(ALU64, LSH,  X)                  \
        INSN_3(ALU64, RSH,  X)                  \
        INSN_3(ALU64, XOR,  X)                  \
        INSN_3(ALU64, MUL,  X)                  \
        INSN_3(ALU64, MOV,  X)                  \
        INSN_3(ALU64, ARSH, X)                  \
        INSN_3(ALU64, DIV,  X)                  \
        INSN_3(ALU64, MOD,  X)                  \
        INSN_2(ALU64, NEG)                      \
        /*   Immediate based. */                \
        INSN_3(ALU64, ADD,  K)                  \
        INSN_3(ALU64, SUB,  K)                  \
        INSN_3(ALU64, AND,  K)                  \
        INSN_3(ALU64, OR,   K)                  \
        INSN_3(ALU64, LSH,  K)                  \
        INSN_3(ALU64, RSH,  K)                  \
        INSN_3(ALU64, XOR,  K)                  \
        INSN_3(ALU64, MUL,  K)                  \
        INSN_3(ALU64, MOV,  K)                  \
        INSN_3(ALU64, ARSH, K)                  \
        INSN_3(ALU64, DIV,  K)                  \
        INSN_3(ALU64, MOD,  K)                  \
        /* Call instruction. */                 \
        INSN_2(JMP, CALL)                       \
        /* Exit instruction. */                 \
        INSN_2(JMP, EXIT)                       \
        /* 32-bit Jump instructions. */         \
        /*   Register based. */                 \
        INSN_3(JMP32, JEQ,  X)                  \
        INSN_3(JMP32, JNE,  X)                  \
        INSN_3(JMP32, JGT,  X)                  \
        INSN_3(JMP32, JLT,  X)                  \
        INSN_3(JMP32, JGE,  X)                  \
        INSN_3(JMP32, JLE,  X)                  \
        INSN_3(JMP32, JSGT, X)                  \
        INSN_3(JMP32, JSLT, X)                  \
        INSN_3(JMP32, JSGE, X)                  \
        INSN_3(JMP32, JSLE, X)                  \
        INSN_3(JMP32, JSET, X)                  \
        /*   Immediate based. */                \
        INSN_3(JMP32, JEQ,  K)                  \
        INSN_3(JMP32, JNE,  K)                  \
        INSN_3(JMP32, JGT,  K)                  \
        INSN_3(JMP32, JLT,  K)                  \
        INSN_3(JMP32, JGE,  K)                  \
        INSN_3(JMP32, JLE,  K)                  \
        INSN_3(JMP32, JSGT, K)                  \
        INSN_3(JMP32, JSLT, K)                  \
        INSN_3(JMP32, JSGE, K)                  \
        INSN_3(JMP32, JSLE, K)                  \
        INSN_3(JMP32, JSET, K)                  \
        /* Jump instructions. */                \
        /*   Register based. */                 \
        INSN_3(JMP, JEQ,  X)                    \
        INSN_3(JMP, JNE,  X)                    \
        INSN_3(JMP, JGT,  X)                    \
        INSN_3(JMP, JLT,  X)                    \
        INSN_3(JMP, JGE,  X)                    \
        INSN_3(JMP, JLE,  X)                    \
        INSN_3(JMP, JSGT, X)                    \
        INSN_3(JMP, JSLT, X)                    \
        INSN_3(JMP, JSGE, X)                    \
        INSN_3(JMP, JSLE, X)                    \
        INSN_3(JMP, JSET, X)                    \
        /*   Immediate based. */                \
        INSN_3(JMP, JEQ,  K)                    \
        INSN_3(JMP, JNE,  K)                    \
        INSN_3(JMP, JGT,  K)                    \
        INSN_3(JMP, JLT,  K)                    \
        INSN_3(JMP, JGE,  K)                    \
        INSN_3(JMP, JLE,  K)                    \
        INSN_3(JMP, JSGT, K)                    \
        INSN_3(JMP, JSLT, K)                    \
        INSN_3(JMP, JSGE, K)                    \
        INSN_3(JMP, JSLE, K)                    \
        INSN_3(JMP, JSET, K)                    \
        INSN_2(JMP, JA)                         \
        /* Store instructions. */               \
        /*   Register based. */                 \
        INSN_3(STX, MEM,  B)                    \
        INSN_3(STX, MEM,  H)                    \
        INSN_3(STX, MEM,  W)                    \
        INSN_3(STX, MEM,  DW)                   \
        INSN_3(STX, XADD, W)                    \
        INSN_3(STX, XADD, DW)                   \
        /*   Immediate based. */                \
        INSN_3(ST, MEM, B)                      \
        INSN_3(ST, MEM, H)                      \
        INSN_3(ST, MEM, W)                      \
        INSN_3(ST, MEM, DW)                     \
        /* Load instructions. */                \
        /*   Register based. */                 \
        INSN_3(LDX, MEM, B)                     \
        INSN_3(LDX, MEM, H)                     \
        INSN_3(LDX, MEM, W)                     \
        INSN_3(LDX, MEM, DW)                    \
        /*   Immediate based. */                \
        INSN_3(LD, IMM, DW)

/**
 *      __bpf_prog_run - run eBPF program on a given context
 *      @regs: is the array of MAX_BPF_EXT_REG eBPF pseudo-registers
 *      @insn: is the array of eBPF instructions
 *
 * Decode and execute eBPF instructions.
 */
static u64 ___bpf_prog_run(u64 *regs, const struct bpf_insn *insn)
{
#define CONT     ({ insn++; goto select_insn; })
#define CONT_JMP ({ insn++; goto select_insn; })

select_insn:
        /*
         * Use switch rather than a jump table directly.
         * This is more flexible as we can suggest to gcc what to emit.
         */
#define BPF_INSN_2_LBL(x, y)    case (BPF_##x | BPF_##y): goto x##_##y;
#define BPF_INSN_3_LBL(x, y, z) case (BPF_##x | BPF_##y | BPF_##z): goto x##_##y##_##z;
        switch (insn->code) {
        default: goto default_label;
        BPF_INSN_MAP(BPF_INSN_2_LBL, BPF_INSN_3_LBL);
        }
#undef BPF_INSN_3_LBL
#undef BPF_INSN_2_LBL

        /* ALU */
#define ALU(OPCODE, OP)                 \
        ALU64_##OPCODE##_X:             \
                DST = DST OP SRC;       \
                CONT;                   \
        ALU_##OPCODE##_X:               \
                DST = (u32) DST OP (u32) SRC;   \
                CONT;                   \
        ALU64_##OPCODE##_K:             \
                DST = DST OP IMM;               \
                CONT;                   \
        ALU_##OPCODE##_K:               \
                DST = (u32) DST OP (u32) IMM;   \
                CONT;

        ALU(ADD,  +)
        ALU(SUB,  -)
        ALU(AND,  &)
        ALU(OR,   |)
        ALU(LSH, <<)
        ALU(RSH, >>)
        ALU(XOR,  ^)
        ALU(MUL,  *)
#undef ALU
        ALU_NEG:
                DST = (u32) -DST;
                CONT;
        ALU64_NEG:
                DST = -DST;
                CONT;
        ALU_MOV_X:
                DST = (u32) SRC;
                CONT;
        ALU_MOV_K:
                DST = (u32) IMM;
                CONT;
        ALU64_MOV_X:
                DST = SRC;
                CONT;
        ALU64_MOV_K:
                DST = IMM;
                CONT;
        LD_IMM_DW:
                DST = (u64) (u32) insn[0].imm | ((u64) (u32) insn[1].imm) << 32;
                insn++;
                CONT;
        ALU_ARSH_X:
                DST = (u64) (u32) ((*(s32 *) &DST) >> SRC);
                CONT;
        ALU_ARSH_K:
                DST = (u64) (u32) ((*(s32 *) &DST) >> IMM);
                CONT;
        ALU64_ARSH_X:
                (*(s64 *) &DST) >>= SRC;
                CONT;
        ALU64_ARSH_K:
                (*(s64 *) &DST) >>= IMM;
                CONT;
        ALU64_MOD_X:
                div64_u64_rem(DST, SRC, &AX);
                DST = AX;
                CONT;
        ALU_MOD_X:
                AX = (u32) DST;
                DST = do_div(AX, (u32) SRC);
                CONT;
        ALU64_MOD_K:
                div64_u64_rem(DST, IMM, &AX);
                DST = AX;
                CONT;
        ALU_MOD_K:
                AX = (u32) DST;
                DST = do_div(AX, (u32) IMM);
                CONT;
        ALU64_DIV_X:
                DST = div64_u64(DST, SRC);
                CONT;
        ALU_DIV_X:
                AX = (u32) DST;
                do_div(AX, (u32) SRC);
                DST = (u32) AX;
                CONT;
        ALU64_DIV_K:
                DST = div64_u64(DST, IMM);
                CONT;
        ALU_DIV_K:
                AX = (u32) DST;
                do_div(AX, (u32) IMM);
                DST = (u32) AX;
                CONT;
        ALU_END_TO_BE:
                switch (IMM) {
                case 16:
                        DST = (__force u16) cpu_to_be16(DST);
                        break;
                case 32:
                        DST = (__force u32) cpu_to_be32(DST);
                        break;
                case 64:
                        DST = (__force u64) cpu_to_be64(DST);
                        break;
                }
                CONT;
        ALU_END_TO_LE:
                switch (IMM) {
                case 16:
                        DST = (__force u16) cpu_to_le16(DST);
                        break;
                case 32:
                        DST = (__force u32) cpu_to_le32(DST);
                        break;
                case 64:
                        DST = (__force u64) cpu_to_le64(DST);
                        break;
                }
                CONT;

        /* CALL */
        JMP_CALL:
                /* Function call scratches BPF_R1-BPF_R5 registers,
                 * preserves BPF_R6-BPF_R9, and stores return value
                 * into BPF_R0.
                 */
                //BPF_R0 = (__bpf_call_base + insn->imm)(BPF_R1, BPF_R2, BPF_R3,
                //                                       BPF_R4, BPF_R5);
                /* FIXME */
                CONT;

        JMP_JA:
                insn += insn->off;
                CONT;
        JMP_EXIT:
                return BPF_R0;
        /* JMP */
#define COND_JMP(SIGN, OPCODE, CMP_OP)                          \
        JMP_##OPCODE##_X:                                       \
                if ((SIGN##64) DST CMP_OP (SIGN##64) SRC) {     \
                        insn += insn->off;                      \
                        CONT_JMP;                               \
                }                                               \
                CONT;                                           \
        JMP32_##OPCODE##_X:                                     \
                if ((SIGN##32) DST CMP_OP (SIGN##32) SRC) {     \
                        insn += insn->off;                      \
                        CONT_JMP;                               \
                }                                               \
                CONT;                                           \
        JMP_##OPCODE##_K:                                       \
                if ((SIGN##64) DST CMP_OP (SIGN##64) IMM) {     \
                        insn += insn->off;                      \
                        CONT_JMP;                               \
                }                                               \
                CONT;                                           \
        JMP32_##OPCODE##_K:                                     \
                if ((SIGN##32) DST CMP_OP (SIGN##32) IMM) {     \
                        insn += insn->off;                      \
                        CONT_JMP;                               \
                }                                               \
                CONT;
        COND_JMP(u, JEQ, ==)
        COND_JMP(u, JNE, !=)
        COND_JMP(u, JGT, >)
        COND_JMP(u, JLT, <)
        COND_JMP(u, JGE, >=)
        COND_JMP(u, JLE, <=)
        COND_JMP(u, JSET, &)
        COND_JMP(s, JSGT, >)
        COND_JMP(s, JSLT, <)
        COND_JMP(s, JSGE, >=)
        COND_JMP(s, JSLE, <=)
#undef COND_JMP
        /* STX and ST and LDX*/
#define LDST(SIZEOP, SIZE)                                              \
        STX_MEM_##SIZEOP:                                               \
                *(SIZE *)(unsigned long) (DST + insn->off) = SRC;       \
                CONT;                                                   \
        ST_MEM_##SIZEOP:                                                \
                *(SIZE *)(unsigned long) (DST + insn->off) = IMM;       \
                CONT;                                                   \
        LDX_MEM_##SIZEOP:                                               \
                DST = *(SIZE *)(unsigned long) (SRC + insn->off);       \
                CONT;

        LDST(B,   u8)
        LDST(H,  u16)
        LDST(W,  u32)
        LDST(DW, u64)
#undef LDST
        STX_XADD_W: /* lock xadd *(u32 *)(dst_reg + off16) += src_reg */
                atomic_add((u32) SRC, (atomic_t *)(unsigned long)
                           (DST + insn->off));
                CONT;
        STX_XADD_DW: /* lock xadd *(u64 *)(dst_reg + off16) += src_reg */
                atomic64_add((u64) SRC, (atomic64_t *)(unsigned long)
                             (DST + insn->off));
                CONT;

        default_label:
                /* If we ever reach this, we have a bug somewhere. Die hard here
                 * instead of just returning 0; we could be somewhere in a subprog,
                 * so execution could continue otherwise which we do /not/ want.
                 *
                 * Note, verifier whitelists all opcodes in bpf_opcode_in_insntable().
                 */
                BUG_ON(1);
                return 0;
}

u8 ctx[0];
u8 stack[MAX_BPF_STACK];
u64 regs[MAX_BPF_EXT_REG];

unsigned int bpf_prog_run(const struct bpf_insn *insn)
{
        FP = (u64) (unsigned long) &stack[MAX_BPF_STACK];
        ARG1 = (u64) (unsigned long) ctx;
        return ___bpf_prog_run(regs, insn);
}
