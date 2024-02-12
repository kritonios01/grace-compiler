	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
	subq	$56, %rsp
	.cfi_def_cfa_offset 64
	movabsq	$8031924123371070792, %rax      # imm = 0x6F77206F6C6C6548
	movq	%rax, 10(%rsp)
	movw	$10, 22(%rsp)
	movl	$560229490, 18(%rsp)            # imm = 0x21646C72
	leaq	10(%rsp), %rdi
	callq	writeString@PLT
	movabsq	$2869948841616757, %rax         # imm = 0xA3234093A6575
	movq	%rax, 48(%rsp)
	movabsq	$7809617830364802401, %rax      # imm = 0x6C61560A22736D61
	movq	%rax, 40(%rsp)
	movabsq	$7224182139546727791, %rax      # imm = 0x644173616C67756F
	movq	%rax, 32(%rsp)
	movabsq	$4909496690201682254, %rax      # imm = 0x4422093A656D614E
	movq	%rax, 24(%rsp)
	leaq	24(%rsp), %rdi
	callq	writeString@PLT
	addq	$56, %rsp
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.type	.Lvars,@object                  # @vars
	.local	.Lvars
	.comm	.Lvars,208,16
	.section	".note.GNU-stack","",@progbits
