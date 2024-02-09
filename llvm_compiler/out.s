	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
	subq	$40, %rsp
	.cfi_def_cfa_offset 48
	movl	$4, %edi
	callq	writeInteger@PLT
	movl	$238, %edi
	callq	writeChar@PLT
	movabsq	$678192113877739559, %rax       # imm = 0x9696C2265276827
	movq	%rax, 13(%rsp)
	movb	$0, 25(%rsp)
	movl	$174349409, 21(%rsp)            # imm = 0xA645C61
	leaq	13(%rsp), %rdi
	callq	writeString@PLT
	movabsq	$8315460637037982566, %rax      # imm = 0x7366736466647366
	movq	%rax, 26(%rsp)
	movw	$115, 38(%rsp)
	movl	$1684431987, 34(%rsp)           # imm = 0x64666473
	leaq	26(%rsp), %rdi
	callq	writeString@PLT
	movb	$0, 12(%rsp)
	movw	$2620, 10(%rsp)                 # imm = 0xA3C
	leaq	10(%rsp), %rdi
	callq	writeString@PLT
	movl	$42, %eax
	addq	$40, %rsp
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
