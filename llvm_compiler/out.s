	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
	subq	$1032, %rsp                     # imm = 0x408
	.cfi_def_cfa_offset 1040
	movq	$0, 24(%rsp)
	movq	$4, 16(%rsp)
	movq	$4, 8(%rsp)
	movq	$50265, 224(%rsp)               # imm = 0xC459
	movl	$50265, %edi                    # imm = 0xC459
	callq	writeInteger@PLT
	movl	$10, %edi
	callq	writeChar@PLT
	movl	$1, %eax
	addq	$1032, %rsp                     # imm = 0x408
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.section	".note.GNU-stack","",@progbits
