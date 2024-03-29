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
	movq	$1, 8(%rsp)
	movl	$1, %edi
	callq	writeInteger@PLT
	leaq	8(%rsp), %rax
	movq	%rax, 16(%rsp)
	leaq	32(%rsp), %rax
	movq	%rax, 24(%rsp)
	leaq	16(%rsp), %rdi
	callq	a@PLT
	movq	8(%rsp), %rdi
	callq	writeInteger@PLT
	addq	$56, %rsp
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end0:
	.size	main, .Lfunc_end0-main
	.cfi_endproc
                                        # -- End function
	.globl	a                               # -- Begin function a
	.p2align	4, 0x90
	.type	a,@function
a:                                      # @a
	.cfi_startproc
# %bb.0:                                # %a_entry
	movq	(%rdi), %rax
	movq	$5, (%rax)
	movl	$42, %eax
	retq
.Lfunc_end1:
	.size	a, .Lfunc_end1-a
	.cfi_endproc
                                        # -- End function
	.type	.Lvars,@object                  # @vars
	.local	.Lvars
	.comm	.Lvars,208,16
	.section	".note.GNU-stack","",@progbits
