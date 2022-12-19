; Author:	Angelo Frasca Caccia (lem0nSec_)
; Date:		19/12/2022
; Title:	Code_03.asm
; Details:	XOR encryption utility: allocate string in the heap, then xor it.
; Website:	https://github.com/lem0nSec/ASM_World


[BITS 64]

section .data
	val		db		0xff		; xor key
	var		db		"I am a plaintext string", 0xa, 0x00
	len		equ		$-var

section .text

	global _start

extern memcpy
extern LocalAlloc
extern LocalFree
extern ExitProcess

_start:
	push rsp
	mov rbp, rsp
	sub rsp, 0x60

	xor rcx, rcx
	mov rdx, rcx
	add rcx, 0x0040
	add rdx, len
	call LocalAlloc					; dst = LocalAlloc(LPTR, strlen(var))
	mov r15, rax					; store the new memory into r15

	mov rcx, rax
	lea rdx, [var]
	mov r8, len
	call memcpy					; memcpy(dst, var, strlen(var))

	xor rax, rax
	mov rdx, rax
	mov rbx, rax
	mov rcx, r15
	add bl, [val]
	call _start_xor					; _start_xor(rcx: destination buffer, rax: counter, dl: zero, bl: xor key)
	
	mov rcx, r15
	call LocalFree					; LocalFree(dst)
	jmp _exit


_start_xor:
	xor BYTE [ds:rcx + rax], bl			; xor byte
	inc rax						; inc counter by 1
	cmp BYTE [ds:rcx + rax], dl			; check for the null terminator (NT)
	jne _start_xor					; if there's NT, jump back to to _start_xor
	ret



_exit:
	xor rcx, rcx
	call ExitProcess				; ExitProcess(0)
