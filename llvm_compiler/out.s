	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
	subq	$24, %rsp
	.cfi_def_cfa_offset 32
	movabsq	$8031924123371070792, %rax      # imm = 0x6F77206F6C6C6548
	movq	%rax, 2(%rsp)
	movw	$10, 14(%rsp)
	movl	$560229490, 10(%rsp)            # imm = 0x21646C72
	leaq	2(%rsp), %rdi
	callq	writeString@PLT
	xorl	%eax, %eax
	addq	$24, %rsp
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
