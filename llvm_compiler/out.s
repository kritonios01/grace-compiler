	.text
	.file	"grace program"
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %main_entry
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
