; Author:	Angelo Frasca Caccia (lem0nSec_)
; Date:		30/12/2022
; Title:	Code_05.asm
; Details:	Find process (lsass.exe) basic information (name, pid).
; Website:	https://github.com/lem0nSec/ASM_World


[BITS 64]


section .data

	name			db		"lsass.exe", 0
	format_str1		db 		"PID: %d", 0xa, 0
	format_str2		db 		"Process Name: %s", 0xa, 0

pe32:
	dwSize			resd	0
	cntUsage		resd	0
	th32ProcessID 		resd 	0
	th32DefaultHeapID	resq	0
	th32ModuleID 		resd	0
	cntThreads		resd	0
	th32ParentProcessID	resd	0
	pcPriClassBase 		resd	0
	dwFlags			resd	0
	szExeFile		resb	260


section .text
	
	global _start

extern CreateToolhelp32Snapshot
extern Process32First
extern Process32Next
extern CloseHandle
extern ExitProcess
extern printf


_start:
	push rsp
	mov rbp, rsp
	sub rsp, 0x60

	xor rdx, rdx
	mov rcx, rdx
	add cl, 0x02
	call CreateToolhelp32Snapshot		; HANDLE hSnap = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
	mov r15, rax				; store hSnap into r15


_findFirst:
	mov rcx, rax
	mov rdx, pe32
	mov DWORD [ds:dwSize], 304
	call Process32First			; Process32First(hSnap, &pe32)
	test rax, rax
	jz _closeHandle


_findNext:
	mov rcx, r15
	mov rdx, pe32
	call Process32Next			; Process32Next(hSnap, &pe32)
	
	test rax, rax
	jz _closeHandle
	
	xor rax, rax
	mov rcx, rax
	mov rdx, rax
	

_compareString:
	mov cl, BYTE [pe32 + 44 + rax]
	mov dl, BYTE [name + rax]
	cmp cl, dl
	jne _findNext
	cmp cl, 0
	jz _printProcessBasicInformation

_compareStringIncrement:
	inc rax
	jmp _compareString


_printProcessBasicInformation:
	xor rdx, rdx
	lea rdx, [pe32 + 44]
	lea rcx, [format_str2]
	call printf

	xor rdx, rdx
	mov dx, [pe32 + 8]
	lea rcx, [format_str1]
	call printf

_closeHandle:
	mov rcx, r15
	call CloseHandle


_null:
	xor rcx, rcx
	call ExitProcess
