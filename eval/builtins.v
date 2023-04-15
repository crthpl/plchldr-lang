module eval

import os
import ast

pub const (
	builtins = {
		'println':  fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('println requires 1 argument')
			}
			println(args[0])
			return Void{}
		}
		'eprintln': fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('eprintln requires 1 argument')
			}
			eprintln(args[0])
			return Void{}
		}
		'print':    fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('print requires 1 argument')
			}
			print(args[0])
			return Void{}
		}
		'eprint':   fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('eprint requires 1 argument')
			}
			eprint(args[0])
			return Void{}
		}
		'assert':   fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('assert requires 1 argument')
			}
			if args[0] is bool {
				if !(args[0] as bool) {
					return Err('assert failed!')
				}
			} else {
				return Err('assert requires a bool type')
			}
			return Void{}
		}
		'args':     fn (mut e Eval, args ...Val) Val {
			if args.len != 0 {
				return Err('args does not take arguments')
			}
			return Array{
				sym: e.table.get_sym(ast.Builtin.string.typ())
				vals: os.args[1..].map(Val(it))
			}
		}
		'exit':     fn (mut e Eval, args ...Val) Val {
			if args.len != 1 {
				return Err('exit takes 1 argument')
			}
			exit(int(args[0] as i64))
		}
		'syscall':  fn (mut e Eval, args ...Val) Val {
			return match args.len {
				0 {
					Err('syscall requires arguments')
				}
				1 {
					syscall0(args[0] as u64)
				}
				2 {
					syscall1(args[0] as u64, args[1] as u64)
				}
				3 {
					syscall2(args[0] as u64, args[1] as u64, args[2] as u64)
				}
				4 {
					syscall3(args[0] as u64, args[1] as u64, args[2] as u64, args[3] as u64)
				}
				5 {
					syscall4(args[0] as u64, args[1] as u64, args[2] as u64, args[3] as u64,
						args[4] as u64)
				}
				6 {
					syscall5(args[0] as u64, args[1] as u64, args[2] as u64, args[3] as u64,
						args[4] as u64, args[5] as u64)
				}
				7 {
					syscall6(args[0] as u64, args[1] as u64, args[2] as u64, args[3] as u64,
						args[4] as u64, args[5] as u64, args[6] as u64)
				}
				else {
					Err('too many arguments to syscall')
				}
			}
		}
	}
	builtin_rets = {
		'println':  [ast.Builtin.void.typ()]
		'eprintln': [ast.Builtin.void.typ()]
		'print':    [ast.Builtin.void.typ()]
		'eprint':   [ast.Builtin.void.typ()]
		'assert':   [ast.Builtin.void.typ()]
		'args':     [ast.Builtin.stringarr.typ()]
		'exit':     [ast.Builtin.void.typ()]
		'syscall':  [ast.Builtin.u64.typ()]
	}
)
