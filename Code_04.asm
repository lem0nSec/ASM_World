; Author:	Angelo Frasca Caccia (lem0nSec_)
; Date:		30/12/2022
; Title:	Code_04.asm
; Details:	Dinamically resolve function addresses: Allocate kernel32.dll addresses in the heap memory, then call them with 'call QWORD [ds:r14 + <int>]'
; Website:	https://github.com/lem0nSec/ASM_World


[BITS 64]


section .data


_kernel32AddressTable:

	k32LocalAlloc		db	"LocalAlloc",	0 	; + 0
	
	k32LocalFree		db	"LocalFree",	0 	; + 8

	k32ExitProcess		db	"ExitProcess",	0 	; + 16

	k32VirtualAlloc		db	"VirtualAlloc",	0 	; + 24

	k32OpenProcess		db	"OpenProcess",	0 	; + 32


section .text

	global _start


_start:
	push rsp
	mov rbp, rsp
	sub rsp, 0x60

	call _get_Kernel32_Handle			; GetModuleHandleA("kernel32.dll")
	mov r12, rax					; *** r12: base addr kernel32.dll ***
	mov rcx, rax
	call _get_function_export			; get GetProcAddress address
	mov r13, rax					; *** r13: GetProcAddress ***

	mov rcx, r12
	lea rdx, [k32LocalAlloc]
	call r13

	mov r15, rax					; r15: store LocalAlloc import for later use

	xor rcx, rcx
	mov rdx, rcx
	add rcx, 0x0040
	add dl, 0x40 
	call rax

	mov r14, rax					; *** r14: address of new memory area ***
	mov rax, r15
	call _prepareStoreAddress			; store LocalAlloc address

	mov rcx, r12
	lea rdx, [k32LocalFree]
	call r13					; GetProcAddress("LocalFree")
	call _prepareStoreAddress			; store LocalFree address

	mov rcx, r12
	lea rdx, [k32ExitProcess]
	call r13					; GetProcAddress("ExitProcess")
	call _prepareStoreAddress			; store ExitProcess address

	mov rcx, r12
	lea rdx, [k32VirtualAlloc]
	call r13					; GetProcAddress("VirtualAlloc")
	call _prepareStoreAddress			; store VirtualAlloc address

	mov rcx, r12
	lea rdx, [k32OpenProcess]
	call r13					; GetProcAddress("OpenProcess")
	call _prepareStoreAddress			; store OpenProcess address

	xor rax, rax
	jmp _begin					; bring execution flow to "_begin" after all function addresses are resolved and stored


; Configuration: storeAddress(rax: import, r14: &dst)
_prepareStoreAddress:
	mov r9, rax
	xor r8, r8
	mov rdx, r8
	mov rcx, r14

_storeAddress:
	cmp QWORD [ds:rcx + rdx], r8
	jne _storeAddress_continueIncrement
	mov QWORD [ds:rcx + rdx], r9
	mov rax, rdx
	ret

_storeAddress_continueIncrement:
	add rdx, 8
	jmp _storeAddress


_get_Kernel32_Handle:
	mov rax, QWORD [gs:0x60]			; TEB
	mov rax, [rax + 18h]				; Ldr
	mov rax, [rax + 20h]				; InMemoryOrderModuleList
	mov rax, [rax]					; skip current module
	mov rax, [rax]					; skip ntdll.dll (ntdll.dll always at the second position)
	mov rax, [rax + 20h]				; kernel32.dll base address
	ret

_get_function_export:
	
	test rcx, rcx
	jz _return_zero					; rcx contains kernel32.dll base address

	mov eax, [rcx + 3Ch]				; IMAGE_DOS_HEADER -> e_lfanew
	add rax, rcx					; IMAGE_NT_HEADER
	lea rax, [rax + 18h]				; IMAGE_OPTIONAL_HEADER
	lea rax, [rax + 70h]				; IMAGE_DATA_DIRECTORY
	lea rax, [rax + 0h]				; IMAGE_DATA_DIRECTORY[IMAGE_DATA_EXPORT_DIRECTORY]

	mov edx, [rax]
	lea rax, [rdx + rcx]				; base of IMAGE_DATA_EXPORT_DIRECTORY

	mov edx, [rax + 18h]				; NumberOfNames
	mov r8d, [rax + 20h]				; AddressOfNames
	lea r8, [rcx + r8]

	mov r10, 41636f7250746547h
	mov r11, 0073736572646441h			; "GetProcAddress"


_loop:
	
	mov r9d, [r8]
	lea r9, [rcx + r9]				; ptr to function name
	cmp r10, [r9]
	jnz _adjust_loop
	cmp r11, [r9 + 7]
	jnz _adjust_loop


	neg rdx
	mov r10d, [rax + 18h]
	lea rdx, [r10 + rdx]
	mov r10d, [rax + 24h]
	lea r10, [rcx + r10]
	movzx rdx, WORD [r10 + rdx * 2]
	mov r10d, [rax + 1Ch]   			; AddressOfFunctions
	lea r10, [rcx + r10]

	mov r10d, [r10 + rdx * 4]			; r10 = offset of possible func addr

	; Check for forwarded function
	mov edx, [rax + 0]				; rdx = VirtualAddress
	cmp r10, rdx
	jb _return_zero

	mov r11d, [rax + 4]				; r11 = Size
	add r11, rdx
	cmp r10, r11

	mov r11d, [rax + 4]				; r11 = Size
	add r11, rdx
	cmp r10, r11
	jae _return_zero

	lea rax, [rcx + r10]      			; Got func addr!
	ret


_adjust_loop:
	
	add r8, 4
	dec rdx
	jnz _loop


_return_zero:
	
	xor rax, rax
	ret

_clearAndTerminateProcess:
	
	; 1) save ExitProcess into r13 for later user
	; 2) clear the allocated memory in the heap where all function addresses are stored
	; 3) call ExitProcess and terminate
	
	mov rcx, r14
	mov r13, QWORD [ds:r14 + 16]
	call QWORD [ds:r14 + 8]				; LocalFree(dst)
	xor rcx, rcx
	call r13					; ExitProcess(0)

_begin:
	
	; Functions are now resolved
	; r14: start of memory regions where function addresses are located


	jmp _clearAndTerminateProcess
