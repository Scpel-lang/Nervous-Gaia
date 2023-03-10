/*
 * AMD Memory Encryption Support
 *
 */

#include <linux/linkage.h>

#include <asm/processor-flags.h>
#include <asm/msr.h>
#include <asm/asm-offsets.h>

	.text
	.code32
SYM_FUNC_START(get_sev_encryption_bit)
	xor	%eax, %eax

#ifdef CONFIG_AMD_MEM_ENCRYPT
	push	%ebx
	push	%ecx
	push	%edx

	movl	$0x80000000, %eax	/* CPUID to check the highest leaf */
	cpuid
	cmpl	$0x8000001f, %eax	/* See if 0x8000001f is available */
	jb	.Lno_sev

	/*
	 * Check for the SEV feature:
	 *   CPUID Fn8000_001F[EAX] - Bit 1
	 *   CPUID Fn8000_001F[EBX] - Bits 5:0
	 *     Pagetable bit position used to indicate encryption
	 */
	movl	$0x8000001f, %eax
	cpuid
	bt	$1, %eax		/* Check if SEV is available */
	jnc	.Lno_sev

	movl	$MSR_AMD64_SEV, %ecx	/* Read the SEV MSR */
	rdmsr
	bt	$MSR_AMD64_SEV_ENABLED_BIT, %eax	/* Check if SEV is active */
	jnc	.Lno_sev

	movl	%ebx, %eax
	andl	$0x3f, %eax		/* Return the encryption bit location */
	jmp	.Lsev_exit

.Lno_sev:
	xor	%eax, %eax

.Lsev_exit:
	pop	%edx
	pop	%ecx
	pop	%ebx

#endif	/* CONFIG_AMD_MEM_ENCRYPT */

	RET
SYM_FUNC_END(get_sev_encryption_bit)

/**
 * sev_es_req_cpuid - Request a CPUID value from the Hypervisor using
 *		      the GHCB MSR protocol
 *
 * @%eax:	Register to request (0=EAX, 1=EBX, 2=ECX, 3=EDX)
 * @%edx:	CPUID Function
 *
 * Returns 0 in %eax on success, non-zero on failure
 * %edx returns CPUID value on success
 */
SYM_CODE_START_LOCAL(sev_es_req_cpuid)
	shll	$30, %eax
	orl     $0x00000004, %eax
	movl    $MSR_AMD64_SEV_ES_GHCB, %ecx
	wrmsr
	rep; vmmcall		# VMGEXIT
	rdmsr

	/* Check response */
	movl	%eax, %ecx
	andl	$0x3ffff000, %ecx	# Bits [12-29] MBZ
	jnz	2f

	/* Check return code */
	andl    $0xfff, %eax
	cmpl    $5, %eax
	jne	2f

	/* All good - return success */
	xorl	%eax, %eax
1:
	RET
2:
	movl	$-1, %eax
	jmp	1b
SYM_CODE_END(sev_es_req_cpuid)

SYM_CODE_START(startup32_vc_handler)
	pushl	%eax
	pushl	%ebx
	pushl	%ecx
	pushl	%edx

	/* Keep CPUID function in %ebx */
	movl	%eax, %ebx

	/* Check if error-code == SVM_EXIT_CPUID */
	cmpl	$0x72, 16(%esp)
	jne	.Lfail

	movl	$0, %eax		# Request CPUID[fn].EAX
	movl	%ebx, %edx		# CPUID fn
	call	sev_es_req_cpuid	# Call helper
	testl	%eax, %eax		# Check return code
	jnz	.Lfail
	movl	%edx, 12(%esp)		# Store result

	movl	$1, %eax		# Request CPUID[fn].EBX
	movl	%ebx, %edx		# CPUID fn
	call	sev_es_req_cpuid	# Call helper
	testl	%eax, %eax		# Check return code
	jnz	.Lfail
	movl	%edx, 8(%esp)		# Store result

	movl	$2, %eax		# Request CPUID[fn].ECX
	movl	%ebx, %edx		# CPUID fn
	call	sev_es_req_cpuid	# Call helper
	testl	%eax, %eax		# Check return code
	jnz	.Lfail
	movl	%edx, 4(%esp)		# Store result

	movl	$3, %eax		# Request CPUID[fn].EDX
	movl	%ebx, %edx		# CPUID fn
	call	sev_es_req_cpuid	# Call helper
	testl	%eax, %eax		# Check return code
	jnz	.Lfail
	movl	%edx, 0(%esp)		# Store result

	/*
	 * Sanity check CPUID results from the Hypervisor. See comment in
	 * do_vc_no_ghcb() for more details on why this is necessary.
	 */

	/* Fail if SEV leaf not available in CPUID[0x80000000].EAX */
	cmpl    $0x80000000, %ebx
	jne     .Lcheck_sev
	cmpl    $0x8000001f, 12(%esp)
	jb      .Lfail
	jmp     .Ldone

.Lcheck_sev:
	/* Fail if SEV bit not set in CPUID[0x8000001f].EAX[1] */
	cmpl    $0x8000001f, %ebx
	jne     .Ldone
	btl     $1, 12(%esp)
	jnc     .Lfail

.Ldone:
	popl	%edx
	popl	%ecx
	popl	%ebx
	popl	%eax

	/* Remove error code */
	addl	$4, %esp

	/* Jump over CPUID instruction */
	addl	$2, (%esp)

	iret
.Lfail:
	/* Send terminate request to Hypervisor */
	movl    $0x100, %eax
	xorl    %edx, %edx
	movl    $MSR_AMD64_SEV_ES_GHCB, %ecx
	wrmsr
	rep; vmmcall

	/* If request fails, go to hlt loop */
	hlt
	jmp .Lfail
SYM_CODE_END(startup32_vc_handler)

	.code64

#include "../../kernel/sev_verify_cbit.S"

	.data

#ifdef CONFIG_AMD_MEM_ENCRYPT
	.balign	8
SYM_DATA(sme_me_mask,		.quad 0)
SYM_DATA(sev_status,		.quad 0)
SYM_DATA(sev_check_data,	.quad 0)
#endif
