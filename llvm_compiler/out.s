	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
	pushq	%rax
	.cfi_def_cfa_offset 16
	movl	$4, %edi
	callq	writeInteger@PLT
	movl	$92, %edi
	callq	writeChar@PLT
	movw	$10, 6(%rsp)
	movl	$1664317532, 2(%rsp)            # imm = 0x6333785C
	leaq	2(%rsp), %rdi
	callq	writeString@PLT
	callq	readInteger@PLT
	movl	$42, %eax
	popq	%rcx
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.type	.Lvars,@object                  # @vars
	.local	.Lvars
	.comm	.Lvars,208,16
	.type	.Lnl,@object                    # @nl
	.section	.rodata,"a",@progbits
.Lnl:
	.asciz	"\n"
	.size	.Lnl, 2

	.section	".note.GNU-stack","",@progbits
