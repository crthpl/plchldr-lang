module eval

fn syscall0(scn u64) u64 {
	mut res := u64(0)
	asm amd64 {
		syscall
		; =a (res)
		; a (scn)
	}
	return res
}

fn syscall1(scn u64, arg1 u64) u64 {
	mut res := u64(0)
	asm amd64 {
		syscall
		; =a (res)
		; a (scn)
		  D (arg1)
	}
	return res
}

fn syscall2(scn u64, arg1 u64, arg2 u64) u64 {
	mut res := u64(0)
	asm amd64 {
		syscall
		; =a (res)
		; a (scn)
		  D (arg1)
		  S (arg2)
	}
	return res
}

fn syscall3(scn u64, arg1 u64, arg2 u64, arg3 u64) u64 {
	mut res := u64(0)
	asm amd64 {
		syscall
		; =a (res)
		; a (scn)
		  D (arg1)
		  S (arg2)
		  d (arg3)
	}
	return res
}

fn syscall4(scn u64, arg1 u64, arg2 u64, arg3 u64, arg4 u64) u64 {
	mut res := u64(0)
	asm amd64 {
		mov r10, arg4
		syscall
		; =a (res)
		; a (scn)
		  D (arg1)
		  S (arg2)
		  d (arg3)
		  r (arg4)
		; r10
	}
	return res
}

fn syscall5(scn u64, arg1 u64, arg2 u64, arg3 u64, arg4 u64, arg5 u64) u64 {
	mut res := u64(0)
	asm amd64 {
		mov r10, arg4
		mov r8, arg5
		syscall
		; =a (res)
		; a (scn)
		  D (arg1)
		  S (arg2)
		  d (arg3)
		  r (arg4)
		  r (arg5)
		; r10
		  r8
	}
	return res
}

fn syscall6(scn u64, arg1 u64, arg2 u64, arg3 u64, arg4 u64, arg5 u64, arg6 u64) u64 {
	panic('syscall6 not implemented')
	// mut res := u64(0)
	// asm amd64 {
	//	mov r10, arg4
	//	mov r8, arg5
	//	mov r9, arg6
	//	syscall
	//	; =a (res)
	//	; a (scn)
	//	  D (arg1)
	//	  S (arg2)
	//	  d (arg3)
	//	  r (arg4)
	//	  r (arg5)
	//	  r (arg6)
	//	; r10
	//	  r8
	//	  r9
	//}
	// return res
}
