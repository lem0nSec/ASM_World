; Author:	Angelo Frasca Caccia (lem0nSec_)
; Date:		12/12/2022
; Title:	Code_02.asm
; Details:	dynamic library (.dll) tester. Call LoadLibraryA on the dll file at $lib, then wait for user input before exiting the program.
; Website:	https://github.com/lem0nSec/ASM_World


[BITS 64]

section .data
	lib	db	"C:\Users\user\Desktop\mod.dll", 0x00		; path to dll
	var	db	"Press a key to exit...", 0xa

section .text

	global _start


extern ExitProcess
extern LoadLibraryA
extern getchar
extern printf

_start:
	push rsp
	mov rbp, rsp
	sub rsp, 0x60

	lea rcx, [lib]
	mov rax, QWORD [ds:LoadLibraryA]
	call rax			; LoadLibraryA((char*)lib)
	test rax, rax
	mov r15, rax			; store the library handle (HMODULE) into r15
	
	lea rcx, [var]
	call printf

	xor rax, rax
	mov rcx, rax
	mov rdx, rax
	mov rax, QWORD [ds:getchar]
	call rax			; getchar() (wait for input before exiting)
	jmp _exit

_exit:
	xor rcx, rcx
	mov rax, QWORD [ds:ExitProcess]
	call rax			; ExitProcess(0)
	
	
