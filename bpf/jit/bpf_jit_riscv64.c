// SPDX-License-Identifier: GPL-2.0
/* BPF JIT compiler for RV64G
 *
 * Copyright(c) 2019 Björn Töpel <bjorn.topel@gmail.com>
 *
 */

#include "bitops.h"
#include "filter.h"

enum {
	RV_REG_ZERO =	0,	/* The constant value 0 */
	RV_REG_RA =	1,	/* Return address */
	RV_REG_SP =	2,	/* Stack pointer */
	RV_REG_GP =	3,	/* Global pointer */
	RV_REG_TP =	4,	/* Thread pointer */
	RV_REG_T0 =	5,	/* Temporaries */
	RV_REG_T1 =	6,
	RV_REG_T2 =	7,
	RV_REG_FP =	8,
	RV_REG_S1 =	9,	/* Saved registers */
	RV_REG_A0 =	10,	/* Function argument/return values */
	RV_REG_A1 =	11,	/* Function arguments */
	RV_REG_A2 =	12,
	RV_REG_A3 =	13,
	RV_REG_A4 =	14,
	RV_REG_A5 =	15,
	RV_REG_A6 =	16,
	RV_REG_A7 =	17,
	RV_REG_S2 =	18,	/* Saved registers */
	RV_REG_S3 =	19,
	RV_REG_S4 =	20,
	RV_REG_S5 =	21,
	RV_REG_S6 =	22,
	RV_REG_S7 =	23,
	RV_REG_S8 =	24,
	RV_REG_S9 =	25,
	RV_REG_S10 =	26,
	RV_REG_S11 =	27,
	RV_REG_T3 =	28,	/* Temporaries */
	RV_REG_T4 =	29,
	RV_REG_T5 =	30,
	RV_REG_T6 =	31,
};

#define RV_REG_TCC RV_REG_A6
#define RV_REG_TCC_SAVED RV_REG_S6 /* Store A6 in S6 if program do calls */

static const int regmap[] = {
	[BPF_REG_0] =	RV_REG_A5,
	[BPF_REG_1] =	RV_REG_A0,
	[BPF_REG_2] =	RV_REG_A1,
	[BPF_REG_3] =	RV_REG_A2,
	[BPF_REG_4] =	RV_REG_A3,
	[BPF_REG_5] =	RV_REG_A4,
	[BPF_REG_6] =	RV_REG_S1,
	[BPF_REG_7] =	RV_REG_S2,
	[BPF_REG_8] =	RV_REG_S3,
	[BPF_REG_9] =	RV_REG_S4,
	[BPF_REG_FP] =	RV_REG_S5,
	[BPF_REG_AX] =	RV_REG_T0,
};

enum {
	RV_CTX_F_SEEN_TAIL_CALL =	0,
	RV_CTX_F_SEEN_CALL =		RV_REG_RA,
	RV_CTX_F_SEEN_S1 =		RV_REG_S1,
	RV_CTX_F_SEEN_S2 =		RV_REG_S2,
	RV_CTX_F_SEEN_S3 =		RV_REG_S3,
	RV_CTX_F_SEEN_S4 =		RV_REG_S4,
	RV_CTX_F_SEEN_S5 =		RV_REG_S5,
	RV_CTX_F_SEEN_S6 =		RV_REG_S6,
};

struct rv_jit_context {
	struct bpf_prog *prog;
	u32 *insns; /* RV insns */
	int ninsns;
	int epilogue_offset;
	int *offset; /* BPF to RV */
	unsigned long flags;
	int stack_size;
};

static u8 bpf_to_rv_reg(int bpf_reg, struct rv_jit_context *ctx)
{
	u8 reg = regmap[bpf_reg];

#if 0
	switch (reg) {
	case RV_CTX_F_SEEN_S1:
	case RV_CTX_F_SEEN_S2:
	case RV_CTX_F_SEEN_S3:
	case RV_CTX_F_SEEN_S4:
	case RV_CTX_F_SEEN_S5:
	case RV_CTX_F_SEEN_S6:
		__set_bit(reg, &ctx->flags);
	}
#endif
	return reg;
};

static void emit(const u32 insn, struct rv_jit_context *ctx)
{
	if (ctx->insns)
		ctx->insns[ctx->ninsns] = insn;

	ctx->ninsns++;
}

static u32 rv_r_insn(u8 funct7, u8 rs2, u8 rs1, u8 funct3, u8 rd, u8 opcode)
{
	return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
		(rd << 7) | opcode;
}

static u32 rv_i_insn(u16 imm11_0, u8 rs1, u8 funct3, u8 rd, u8 opcode)
{
	return (imm11_0 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) |
		opcode;
}

static u32 rv_s_insn(u16 imm11_0, u8 rs2, u8 rs1, u8 funct3, u8 opcode)
{
	u8 imm11_5 = imm11_0 >> 5, imm4_0 = imm11_0 & 0x1f;

	return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
		(imm4_0 << 7) | opcode;
}

static u32 rv_sb_insn(u16 imm12_1, u8 rs2, u8 rs1, u8 funct3, u8 opcode)
{
	u8 imm12 = ((imm12_1 & 0x800) >> 5) | ((imm12_1 & 0x3f0) >> 4);
	u8 imm4_1 = ((imm12_1 & 0xf) << 1) | ((imm12_1 & 0x400) >> 10);

	return (imm12 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) |
		(imm4_1 << 7) | opcode;
}

static u32 rv_u_insn(u32 imm31_12, u8 rd, u8 opcode)
{
	return (imm31_12 << 12) | (rd << 7) | opcode;
}

static u32 rv_uj_insn(u32 imm20_1, u8 rd, u8 opcode)
{
	u32 imm;

	imm = (imm20_1 & 0x80000) |  ((imm20_1 & 0x3ff) << 9) |
	      ((imm20_1 & 0x400) >> 2) | ((imm20_1 & 0x7f800) >> 11);

	return (imm << 12) | (rd << 7) | opcode;
}

static u32 rv_amo_insn(u8 funct5, u8 aq, u8 rl, u8 rs2, u8 rs1,
		       u8 funct3, u8 rd, u8 opcode)
{
	u8 funct7 = (funct5 << 2) | (aq << 1) | rl;

	return rv_r_insn(funct7, rs2, rs1, funct3, rd, opcode);
}

static u32 rv_addiw(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 0, rd, 0x1b);
}

static u32 rv_addi(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 0, rd, 0x13);
}

static u32 rv_addw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 0, rd, 0x3b);
}

static u32 rv_add(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 0, rd, 0x33);
}

static u32 rv_subw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0x20, rs2, rs1, 0, rd, 0x3b);
}

static u32 rv_sub(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0x20, rs2, rs1, 0, rd, 0x33);
}

static u32 rv_and(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 7, rd, 0x33);
}

static u32 rv_or(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 6, rd, 0x33);
}

static u32 rv_xor(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 4, rd, 0x33);
}

static u32 rv_mulw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 0, rd, 0x3b);
}

static u32 rv_mul(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 0, rd, 0x33);
}

static u32 rv_divuw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 5, rd, 0x3b);
}

static u32 rv_divu(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 5, rd, 0x33);
}

static u32 rv_remuw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 7, rd, 0x3b);
}

static u32 rv_remu(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(1, rs2, rs1, 7, rd, 0x33);
}

static u32 rv_sllw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 1, rd, 0x3b);
}

static u32 rv_sll(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 1, rd, 0x33);
}

static u32 rv_srlw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 5, rd, 0x3b);
}

static u32 rv_srl(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0, rs2, rs1, 5, rd, 0x33);
}

static u32 rv_sraw(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0x20, rs2, rs1, 5, rd, 0x3b);
}

static u32 rv_sra(u8 rd, u8 rs1, u8 rs2)
{
	return rv_r_insn(0x20, rs2, rs1, 5, rd, 0x33);
}

static u32 rv_lui(u8 rd, u32 imm31_12)
{
	return rv_u_insn(imm31_12, rd, 0x37);
}

static u32 rv_slli(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 1, rd, 0x13);
}

static u32 rv_andi(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 7, rd, 0x13);
}

static u32 rv_ori(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 6, rd, 0x13);
}

static u32 rv_xori(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 4, rd, 0x13);
}

static u32 rv_slliw(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 1, rd, 0x1b);
}

static u32 rv_srliw(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 5, rd, 0x1b);
}

static u32 rv_srli(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 5, rd, 0x13);
}

static u32 rv_sraiw(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(0x400 | imm11_0, rs1, 5, rd, 0x1b);
}

static u32 rv_srai(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(0x400 | imm11_0, rs1, 5, rd, 0x13);
}

static u32 rv_jal(u8 rd, u32 imm20_1)
{
	return rv_uj_insn(imm20_1, rd, 0x6f);
}

static u32 rv_jalr(u8 rd, u8 rs1, u16 imm11_0)
{
	return rv_i_insn(imm11_0, rs1, 0, rd, 0x67);
}

static u32 rv_beq(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 0, 0x63);
}

static u32 rv_bltu(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 6, 0x63);
}

static u32 rv_bgeu(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 7, 0x63);
}

static u32 rv_bne(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 1, 0x63);
}

static u32 rv_blt(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 4, 0x63);
}

static u32 rv_bge(u8 rs1, u8 rs2, u16 imm12_1)
{
	return rv_sb_insn(imm12_1, rs2, rs1, 5, 0x63);
}

static u32 rv_sb(u8 rs1, u16 imm11_0, u8 rs2)
{
	return rv_s_insn(imm11_0, rs2, rs1, 0, 0x23);
}

static u32 rv_sh(u8 rs1, u16 imm11_0, u8 rs2)
{
	return rv_s_insn(imm11_0, rs2, rs1, 1, 0x23);
}

static u32 rv_sw(u8 rs1, u16 imm11_0, u8 rs2)
{
	return rv_s_insn(imm11_0, rs2, rs1, 2, 0x23);
}

static u32 rv_sd(u8 rs1, u16 imm11_0, u8 rs2)
{
	return rv_s_insn(imm11_0, rs2, rs1, 3, 0x23);
}

static u32 rv_lbu(u8 rd, u16 imm11_0, u8 rs1)
{
	return rv_i_insn(imm11_0, rs1, 4, rd, 0x03);
}

static u32 rv_lhu(u8 rd, u16 imm11_0, u8 rs1)
{
	return rv_i_insn(imm11_0, rs1, 5, rd, 0x03);
}

static u32 rv_lwu(u8 rd, u16 imm11_0, u8 rs1)
{
	return rv_i_insn(imm11_0, rs1, 6, rd, 0x03);
}

static u32 rv_ld(u8 rd, u16 imm11_0, u8 rs1)
{
	return rv_i_insn(imm11_0, rs1, 3, rd, 0x03);
}

static u32 rv_amoadd_w(u8 rd, u8 rs2, u8 rs1, u8 aq, u8 rl)
{
	return rv_amo_insn(0, aq, rl, rs2, rs1, 2, rd, 0x2f);
}

static u32 rv_amoadd_d(u8 rd, u8 rs2, u8 rs1, u8 aq, u8 rl)
{
	return rv_amo_insn(0, aq, rl, rs2, rs1, 3, rd, 0x2f);
}

static bool is_12b_int(s64 val)
{
	return -(1 << 11) <= val && val < (1 << 11);
}

static bool is_13b_int(s64 val)
{
	return -(1 << 12) <= val && val < (1 << 12);
}

static bool is_21b_int(s64 val)
{
	return -(1L << 20) <= val && val < (1L << 20);
}

static bool is_32b_int(s64 val)
{
	return -(1L << 31) <= val && val < (1L << 31);
}

static int is_12b_check(int off, int insn)
{
	if (!is_12b_int(off)) {
		pr_err("bpf-jit: insn=%d offset=%d not supported yet!\n",
		       insn, (int)off);
		return -1;
	}
	return 0;
}

static int is_13b_check(int off, int insn)
{
	if (!is_13b_int(off)) {
		pr_err("bpf-jit: insn=%d offset=%d not supported yet!\n",
		       insn, (int)off);
		return -1;
	}
	return 0;
}

static int is_21b_check(int off, int insn)
{
	if (!is_21b_int(off)) {
		pr_err("bpf-jit: insn=%d offset=%d not supported yet!\n",
		       insn, (int)off);
		return -1;
	}
	return 0;
}

static void emit_imm(u8 rd, s64 val, struct rv_jit_context *ctx)
{
	/* Note that the immediate from the add is sign-extended,
	 * which means that we need to compensate this by adding 2^12,
	 * when the 12th bit is set. A simpler way of doing this, and
	 * getting rid of the check, is to just add 2**11 before the
	 * shift. The "Loading a 32-Bit constant" example from the
	 * "Computer Organization and Design, RISC-V edition" book by
	 * Patterson/Hennessy highlights this fact.
	 *
	 * This also means that we need to process LSB to MSB.
	 */
	s64 upper = (val + (1 << 11)) >> 12, lower = val & 0xfff;
	int shift;

	if (is_32b_int(val)) {
		if (upper)
			emit(rv_lui(rd, upper), ctx);

		if (!upper) {
			emit(rv_addi(rd, RV_REG_ZERO, lower), ctx);
			return;
		}

		emit(rv_addiw(rd, rd, lower), ctx);
		return;
	}

	shift = __ffs(upper);
	upper >>= shift;
	shift += 12;

	emit_imm(rd, upper, ctx);

	emit(rv_slli(rd, rd, shift), ctx);
	if (lower)
		emit(rv_addi(rd, rd, lower), ctx);
}

static int rv_offset(int bpf_to, int bpf_from, struct rv_jit_context *ctx)
{
	int from = ctx->offset[bpf_from] - 1, to = ctx->offset[bpf_to];

	return (to - from) << 2;
}

static void emit_zext_32(u8 reg, struct rv_jit_context *ctx)
{
	emit(rv_slli(reg, reg, 32), ctx);
	emit(rv_srli(reg, reg, 32), ctx);
}

static void init_regs(u8 *rd, u8 *rs, const struct bpf_insn *insn,
		      struct rv_jit_context *ctx)
{
	u8 code = insn->code;

	switch (code) {
	case BPF_JMP | BPF_JA:
	case BPF_JMP | BPF_CALL:
	case BPF_JMP | BPF_EXIT:
	case BPF_JMP | BPF_TAIL_CALL:
		break;
	default:
		*rd = bpf_to_rv_reg(insn->dst_reg, ctx);
	}

	if (code & (BPF_ALU | BPF_X) || code & (BPF_ALU64 | BPF_X) ||
	    code & (BPF_JMP | BPF_X) || code & (BPF_JMP32 | BPF_X) ||
	    code & BPF_LDX || code & BPF_STX)
		*rs = bpf_to_rv_reg(insn->src_reg, ctx);
}

static int rv_offset_check(int *rvoff, s16 off, int insn,
			   struct rv_jit_context *ctx)
{
	*rvoff = rv_offset(insn + off, insn, ctx);
	return is_13b_check(*rvoff, insn);
}

static void emit_zext_32_rd_rs(u8 *rd, u8 *rs, struct rv_jit_context *ctx)
{
	emit(rv_addi(RV_REG_T2, *rd, 0), ctx);
	emit_zext_32(RV_REG_T2, ctx);
	emit(rv_addi(RV_REG_T1, *rs, 0), ctx);
	emit_zext_32(RV_REG_T1, ctx);
	*rd = RV_REG_T2;
	*rs = RV_REG_T1;
}

static void emit_sext_32_rd_rs(u8 *rd, u8 *rs, struct rv_jit_context *ctx)
{
	emit(rv_addiw(RV_REG_T2, *rd, 0), ctx);
	emit(rv_addiw(RV_REG_T1, *rs, 0), ctx);
	*rd = RV_REG_T2;
	*rs = RV_REG_T1;
}

static void emit_zext_32_rd_t1(u8 *rd, struct rv_jit_context *ctx)
{
	emit(rv_addi(RV_REG_T2, *rd, 0), ctx);
	emit_zext_32(RV_REG_T2, ctx);
	emit_zext_32(RV_REG_T1, ctx);
	*rd = RV_REG_T2;
}

static void emit_sext_32_rd(u8 *rd, struct rv_jit_context *ctx)
{
	emit(rv_addiw(RV_REG_T2, *rd, 0), ctx);
	*rd = RV_REG_T2;
}

int emit_insn(const struct bpf_insn *insn, int i, struct rv_jit_context *ctx)
{
	bool is64 = BPF_CLASS(insn->code) == BPF_ALU64 ||
		    BPF_CLASS(insn->code) == BPF_JMP;
	int rvoff;
	u8 rd = -1, rs = -1, code = insn->code;
	s16 off = insn->off;
	s32 imm = insn->imm;

	init_regs(&rd, &rs, insn, ctx);

	switch (code) {
	/* dst = src */
	case BPF_ALU | BPF_MOV | BPF_X:
	case BPF_ALU64 | BPF_MOV | BPF_X:
		emit(is64 ? rv_addi(rd, rs, 0) : rv_addiw(rd, rs, 0), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;

	/* dst = dst OP src */
	case BPF_ALU | BPF_ADD | BPF_X:
	case BPF_ALU64 | BPF_ADD | BPF_X:
		emit(is64 ? rv_add(rd, rd, rs) : rv_addw(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_SUB | BPF_X:
	case BPF_ALU64 | BPF_SUB | BPF_X:
		emit(is64 ? rv_sub(rd, rd, rs) : rv_subw(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_AND | BPF_X:
	case BPF_ALU64 | BPF_AND | BPF_X:
		emit(rv_and(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_OR | BPF_X:
	case BPF_ALU64 | BPF_OR | BPF_X:
		emit(rv_or(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_XOR | BPF_X:
	case BPF_ALU64 | BPF_XOR | BPF_X:
		emit(rv_xor(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_MUL | BPF_X:
	case BPF_ALU64 | BPF_MUL | BPF_X:
		emit(is64 ? rv_mul(rd, rd, rs) : rv_mulw(rd, rd, rs), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_DIV | BPF_X:
	case BPF_ALU64 | BPF_DIV | BPF_X:
		emit(is64 ? rv_divu(rd, rd, rs) : rv_divuw(rd, rd, rs), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_MOD | BPF_X:
	case BPF_ALU64 | BPF_MOD | BPF_X:
		emit(is64 ? rv_remu(rd, rd, rs) : rv_remuw(rd, rd, rs), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_LSH | BPF_X:
	case BPF_ALU64 | BPF_LSH | BPF_X:
		emit(is64 ? rv_sll(rd, rd, rs) : rv_sllw(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_RSH | BPF_X:
	case BPF_ALU64 | BPF_RSH | BPF_X:
		emit(is64 ? rv_srl(rd, rd, rs) : rv_srlw(rd, rd, rs), ctx);
		break;
	case BPF_ALU | BPF_ARSH | BPF_X:
	case BPF_ALU64 | BPF_ARSH | BPF_X:
		emit(is64 ? rv_sra(rd, rd, rs) : rv_sraw(rd, rd, rs), ctx);
		break;

	/* dst = -dst */
	case BPF_ALU | BPF_NEG:
	case BPF_ALU64 | BPF_NEG:
		emit(is64 ? rv_sub(rd, RV_REG_ZERO, rd) :
		     rv_subw(rd, RV_REG_ZERO, rd), ctx);
		break;

	/* dst = BSWAP##imm(dst) */
	case BPF_ALU | BPF_END | BPF_FROM_LE:
	{
		int shift = 64 - imm;

		emit(rv_slli(rd, rd, shift), ctx);
		emit(rv_srli(rd, rd, shift), ctx);
		break;
	}
	case BPF_ALU | BPF_END | BPF_FROM_BE:
		emit(rv_addi(RV_REG_T2, RV_REG_ZERO, 0), ctx);

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);
		if (imm == 16)
			goto out_be;

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);
		if (imm == 32)
			goto out_be;

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);

		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);
		emit(rv_slli(RV_REG_T2, RV_REG_T2, 8), ctx);
		emit(rv_srli(rd, rd, 8), ctx);
out_be:
		emit(rv_andi(RV_REG_T1, rd, 0xff), ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, RV_REG_T1), ctx);

		emit(rv_addi(rd, RV_REG_T2, 0), ctx);
		break;

	/* dst = imm */
	case BPF_ALU | BPF_MOV | BPF_K:
	case BPF_ALU64 | BPF_MOV | BPF_K:
		emit_imm(rd, imm, ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;

	/* dst = dst OP imm */
	case BPF_ALU | BPF_ADD | BPF_K:
	case BPF_ALU64 | BPF_ADD | BPF_K:
		if (is_12b_int(imm)) {
			emit(is64 ? rv_addi(rd, rd, imm) :
			     rv_addiw(rd, rd, imm), ctx);
		} else {
			emit_imm(RV_REG_T1, imm, ctx);
			emit(is64 ? rv_add(rd, rd, RV_REG_T1) :
			     rv_addw(rd, rd, RV_REG_T1), ctx);
		}
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_SUB | BPF_K:
	case BPF_ALU64 | BPF_SUB | BPF_K:
		if (is_12b_int(-imm)) {
			emit(is64 ? rv_addi(rd, rd, -imm) :
			     rv_addiw(rd, rd, -imm), ctx);
		} else {
			emit_imm(RV_REG_T1, imm, ctx);
			emit(is64 ? rv_sub(rd, rd, RV_REG_T1) :
			     rv_subw(rd, rd, RV_REG_T1), ctx);
		}
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_AND | BPF_K:
	case BPF_ALU64 | BPF_AND | BPF_K:
		if (is_12b_int(imm)) {
			emit(rv_andi(rd, rd, imm), ctx);
		} else {
			emit_imm(RV_REG_T1, imm, ctx);
			emit(rv_and(rd, rd, RV_REG_T1), ctx);
		}
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_OR | BPF_K:
	case BPF_ALU64 | BPF_OR | BPF_K:
		if (is_12b_int(imm)) {
			emit(rv_ori(rd, rd, imm), ctx);
		} else {
			emit_imm(RV_REG_T1, imm, ctx);
			emit(rv_or(rd, rd, RV_REG_T1), ctx);
		}
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_XOR | BPF_K:
	case BPF_ALU64 | BPF_XOR | BPF_K:
		if (is_12b_int(imm)) {
			emit(rv_xori(rd, rd, imm), ctx);
		} else {
			emit_imm(RV_REG_T1, imm, ctx);
			emit(rv_xor(rd, rd, RV_REG_T1), ctx);
		}
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_MUL | BPF_K:
	case BPF_ALU64 | BPF_MUL | BPF_K:
		emit_imm(RV_REG_T1, imm, ctx);
		emit(is64 ? rv_mul(rd, rd, RV_REG_T1) :
		     rv_mulw(rd, rd, RV_REG_T1), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_DIV | BPF_K:
	case BPF_ALU64 | BPF_DIV | BPF_K:
		emit_imm(RV_REG_T1, imm, ctx);
		emit(is64 ? rv_divu(rd, rd, RV_REG_T1) :
		     rv_divuw(rd, rd, RV_REG_T1), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_MOD | BPF_K:
	case BPF_ALU64 | BPF_MOD | BPF_K:
		emit_imm(RV_REG_T1, imm, ctx);
		emit(is64 ? rv_remu(rd, rd, RV_REG_T1) :
		     rv_remuw(rd, rd, RV_REG_T1), ctx);
		if (!is64)
			emit_zext_32(rd, ctx);
		break;
	case BPF_ALU | BPF_LSH | BPF_K:
	case BPF_ALU64 | BPF_LSH | BPF_K:
		emit(is64 ? rv_slli(rd, rd, imm) : rv_slliw(rd, rd, imm), ctx);
		break;
	case BPF_ALU | BPF_RSH | BPF_K:
	case BPF_ALU64 | BPF_RSH | BPF_K:
		emit(is64 ? rv_srli(rd, rd, imm) : rv_srliw(rd, rd, imm), ctx);
		break;
	case BPF_ALU | BPF_ARSH | BPF_K:
	case BPF_ALU64 | BPF_ARSH | BPF_K:
		emit(is64 ? rv_srai(rd, rd, imm) : rv_sraiw(rd, rd, imm), ctx);
		break;

	/* JUMP off */
	case BPF_JMP | BPF_JA:
		rvoff = rv_offset(i + off, i, ctx);
		if (!is_21b_int(rvoff)) {
			pr_err("bpf-jit: insn=%d offset=%d not supported yet!\n",
			       i, rvoff);
			return -1;
		}

		emit(rv_jal(RV_REG_ZERO, rvoff >> 1), ctx);
		break;

	/* IF (dst COND src) JUMP off */
	case BPF_JMP | BPF_JEQ | BPF_X:
	case BPF_JMP32 | BPF_JEQ | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_beq(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JGT | BPF_X:
	case BPF_JMP32 | BPF_JGT | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bltu(rs, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JLT | BPF_X:
	case BPF_JMP32 | BPF_JLT | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bltu(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JGE | BPF_X:
	case BPF_JMP32 | BPF_JGE | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bgeu(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JLE | BPF_X:
	case BPF_JMP32 | BPF_JLE | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bgeu(rs, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JNE | BPF_X:
	case BPF_JMP32 | BPF_JNE | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bne(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSGT | BPF_X:
	case BPF_JMP32 | BPF_JSGT | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_sext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_blt(rs, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSLT | BPF_X:
	case BPF_JMP32 | BPF_JSLT | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_sext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_blt(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSGE | BPF_X:
	case BPF_JMP32 | BPF_JSGE | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_sext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bge(rd, rs, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSLE | BPF_X:
	case BPF_JMP32 | BPF_JSLE | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_sext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_bge(rs, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSET | BPF_X:
	case BPF_JMP32 | BPF_JSET | BPF_X:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		if (!is64)
			emit_zext_32_rd_rs(&rd, &rs, ctx);
		emit(rv_and(RV_REG_T1, rd, rs), ctx);
		emit(rv_bne(RV_REG_T1, RV_REG_ZERO, rvoff >> 1), ctx);
		break;

	/* IF (dst COND imm) JUMP off */
	case BPF_JMP | BPF_JEQ | BPF_K:
	case BPF_JMP32 | BPF_JEQ | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_beq(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JGT | BPF_K:
	case BPF_JMP32 | BPF_JGT | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_bltu(RV_REG_T1, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JLT | BPF_K:
	case BPF_JMP32 | BPF_JLT | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_bltu(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JGE | BPF_K:
	case BPF_JMP32 | BPF_JGE | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_bgeu(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JLE | BPF_K:
	case BPF_JMP32 | BPF_JLE | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_bgeu(RV_REG_T1, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JNE | BPF_K:
	case BPF_JMP32 | BPF_JNE | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_bne(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSGT | BPF_K:
	case BPF_JMP32 | BPF_JSGT | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_sext_32_rd(&rd, ctx);
		emit(rv_blt(RV_REG_T1, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSLT | BPF_K:
	case BPF_JMP32 | BPF_JSLT | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_sext_32_rd(&rd, ctx);
		emit(rv_blt(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSGE | BPF_K:
	case BPF_JMP32 | BPF_JSGE | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_sext_32_rd(&rd, ctx);
		emit(rv_bge(rd, RV_REG_T1, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSLE | BPF_K:
	case BPF_JMP32 | BPF_JSLE | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_sext_32_rd(&rd, ctx);
		emit(rv_bge(RV_REG_T1, rd, rvoff >> 1), ctx);
		break;
	case BPF_JMP | BPF_JSET | BPF_K:
	case BPF_JMP32 | BPF_JSET | BPF_K:
		if (rv_offset_check(&rvoff, off, i, ctx))
			return -1;
		emit_imm(RV_REG_T1, imm, ctx);
		if (!is64)
			emit_zext_32_rd_t1(&rd, ctx);
		emit(rv_and(RV_REG_T1, rd, RV_REG_T1), ctx);
		emit(rv_bne(RV_REG_T1, RV_REG_ZERO, rvoff >> 1), ctx);
		break;

#if 0
	/* function call */
	case BPF_JMP | BPF_CALL:
	{
		bool fixed;
		int i, ret;
		u64 addr;

		mark_call(ctx);
		ret = bpf_jit_get_func_addr(ctx->prog, insn, extra_pass, &addr,
					    &fixed);
		if (ret < 0)
			return ret;
		if (fixed) {
			emit_imm(RV_REG_T1, addr, ctx);
		} else {
			i = ctx->ninsns;
			emit_imm(RV_REG_T1, addr, ctx);
			for (i = ctx->ninsns - i; i < 8; i++) {
				/* nop */
				emit(rv_addi(RV_REG_ZERO, RV_REG_ZERO, 0),
				     ctx);
			}
		}
		emit(rv_jalr(RV_REG_RA, RV_REG_T1, 0), ctx);
		rd = bpf_to_rv_reg(BPF_REG_0, ctx);
		emit(rv_addi(rd, RV_REG_A0, 0), ctx);
		break;
	}
	/* tail call */
	case BPF_JMP | BPF_TAIL_CALL:
		if (emit_bpf_tail_call(i, ctx))
			return -1;
		break;

	/* function return */
	case BPF_JMP | BPF_EXIT:
		if (i == ctx->prog->len - 1)
			break;

		rvoff = epilogue_offset(ctx);
		if (is_21b_check(rvoff, i))
			return -1;
		emit(rv_jal(RV_REG_ZERO, rvoff >> 1), ctx);
		break;
#endif

	/* dst = imm64 */
	case BPF_LD | BPF_IMM | BPF_DW:
	{
		struct bpf_insn insn1 = insn[1];
		u64 imm64;

		imm64 = (u64)insn1.imm << 32 | (u32)imm;
		emit_imm(rd, imm64, ctx);
		return 1;
	}

	/* LDX: dst = *(size *)(src + off) */
	case BPF_LDX | BPF_MEM | BPF_B:
		if (is_12b_int(off)) {
			emit(rv_lbu(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rs), ctx);
		emit(rv_lbu(rd, 0, RV_REG_T1), ctx);
		break;
	case BPF_LDX | BPF_MEM | BPF_H:
		if (is_12b_int(off)) {
			emit(rv_lhu(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rs), ctx);
		emit(rv_lhu(rd, 0, RV_REG_T1), ctx);
		break;
	case BPF_LDX | BPF_MEM | BPF_W:
		if (is_12b_int(off)) {
			emit(rv_lwu(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rs), ctx);
		emit(rv_lwu(rd, 0, RV_REG_T1), ctx);
		break;
	case BPF_LDX | BPF_MEM | BPF_DW:
		if (is_12b_int(off)) {
			emit(rv_ld(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rs), ctx);
		emit(rv_ld(rd, 0, RV_REG_T1), ctx);
		break;

	/* ST: *(size *)(dst + off) = imm */
	case BPF_ST | BPF_MEM | BPF_B:
		emit_imm(RV_REG_T1, imm, ctx);
		if (is_12b_int(off)) {
			emit(rv_sb(rd, off, RV_REG_T1), ctx);
			break;
		}

		emit_imm(RV_REG_T2, off, ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, rd), ctx);
		emit(rv_sb(RV_REG_T2, 0, RV_REG_T1), ctx);
		break;

	case BPF_ST | BPF_MEM | BPF_H:
		emit_imm(RV_REG_T1, imm, ctx);
		if (is_12b_int(off)) {
			emit(rv_sh(rd, off, RV_REG_T1), ctx);
			break;
		}

		emit_imm(RV_REG_T2, off, ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, rd), ctx);
		emit(rv_sh(RV_REG_T2, 0, RV_REG_T1), ctx);
		break;
	case BPF_ST | BPF_MEM | BPF_W:
		emit_imm(RV_REG_T1, imm, ctx);
		if (is_12b_int(off)) {
			emit(rv_sw(rd, off, RV_REG_T1), ctx);
			break;
		}

		emit_imm(RV_REG_T2, off, ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, rd), ctx);
		emit(rv_sw(RV_REG_T2, 0, RV_REG_T1), ctx);
		break;
	case BPF_ST | BPF_MEM | BPF_DW:
		emit_imm(RV_REG_T1, imm, ctx);
		if (is_12b_int(off)) {
			emit(rv_sd(rd, off, RV_REG_T1), ctx);
			break;
		}

		emit_imm(RV_REG_T2, off, ctx);
		emit(rv_add(RV_REG_T2, RV_REG_T2, rd), ctx);
		emit(rv_sd(RV_REG_T2, 0, RV_REG_T1), ctx);
		break;

	/* STX: *(size *)(dst + off) = src */
	case BPF_STX | BPF_MEM | BPF_B:
		if (is_12b_int(off)) {
			emit(rv_sb(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rd), ctx);
		emit(rv_sb(RV_REG_T1, 0, rs), ctx);
		break;
	case BPF_STX | BPF_MEM | BPF_H:
		if (is_12b_int(off)) {
			emit(rv_sh(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rd), ctx);
		emit(rv_sh(RV_REG_T1, 0, rs), ctx);
		break;
	case BPF_STX | BPF_MEM | BPF_W:
		if (is_12b_int(off)) {
			emit(rv_sw(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rd), ctx);
		emit(rv_sw(RV_REG_T1, 0, rs), ctx);
		break;
	case BPF_STX | BPF_MEM | BPF_DW:
		if (is_12b_int(off)) {
			emit(rv_sd(rd, off, rs), ctx);
			break;
		}

		emit_imm(RV_REG_T1, off, ctx);
		emit(rv_add(RV_REG_T1, RV_REG_T1, rd), ctx);
		emit(rv_sd(RV_REG_T1, 0, rs), ctx);
		break;
	/* STX XADD: lock *(u32 *)(dst + off) += src */
	case BPF_STX | BPF_XADD | BPF_W:
	/* STX XADD: lock *(u64 *)(dst + off) += src */
	case BPF_STX | BPF_XADD | BPF_DW:
		if (off) {
			if (is_12b_int(off)) {
				emit(rv_addi(RV_REG_T1, rd, off), ctx);
			} else {
				emit_imm(RV_REG_T1, off, ctx);
				emit(rv_add(RV_REG_T1, RV_REG_T1, rd), ctx);
			}

			rd = RV_REG_T1;
		}

		emit(BPF_SIZE(code) == BPF_W ?
		     rv_amoadd_w(RV_REG_ZERO, rs, rd, 0, 0) :
		     rv_amoadd_d(RV_REG_ZERO, rs, rd, 0, 0), ctx);
		break;
	default:
		pr_err("bpf-jit: unknown opcode %02x\n", code);
		return -1;
	}

	return 0;
}
