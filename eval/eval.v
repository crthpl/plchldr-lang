module eval

import ast
import token
import util

struct Eval {
	table &ast.Table
mut:
	file        &ast.File
	global_vars map[string]Val
	local_ptrs  map[string]int
	modules     map[string]map[string]Object
	stack       []Val
	returning   bool
	breaking    bool
}

pub fn eval(asts []&ast.File, table &ast.Table) {
	mut e := Eval{
		file: asts[0]
		table: table
	}
	mut main_file := &ast.File(0)
	for file in asts {
		e.file = file
		e.modules[file.full_mod] = {}
		for decl in file.decls.stmts {
			match decl {
				ast.FnStmt {
					e.modules[decl.full_mod][decl.short_name] = Object(ast.FnStmt{
						...decl
					})
					if decl.name == 'main.main' && decl.full_mod == 'main' {
						main_file = file
					}
				}
				ast.ImportStmt, ast.Struct {}
				ast.AssignStmt {
					if decl.op != .decl_assign {
						e.error('top-level assignment only allowed with decleration assignment',
							decl.pos)
					}
					if decl.left is ast.Ident {
						e.global_vars['${file.full_mod}.$decl.left.name'] = e.expr(decl.right)
					} else {
						e.error('invalid decl assignment', decl.pos)
					}
				}
				else {
					e.error('top level statement cannot be a `$decl.type_name()` $decl',
						decl.pos)
				}
			}
		}
	}
	e.file = main_file

	e.run_func(ast.SelectorExpr{
		left: ast.Ident{
			name: 'main'
		}
		sel: 'main'
	})
}

[noreturn]
fn (e Eval) error(err string, pos token.Pos) {
	util.error(e.file.filename, pos, 'eval', '$e.file.filename: error: $err')
	exit(1)
}

fn (mut e Eval) run_func(f ast.Expr, args ...Val) Val {
	if f is ast.Ident {
		if f.name in builtins {
			fun := builtins[f.name]
			arg := args.clone()
			ret := fun(mut e, ...arg)
			if ret is Err {
				e.error('Exception: $ret', f.pos)
			}
			return ret
		}
	}
	fun := e.expr(f) as Function
	prev_file := e.file
	defer {
		e.file = prev_file
	}
	e.file = fun.f.file
	prev_ptrs := e.local_ptrs.move()
	e.local_ptrs = {}
	if fun.f.recv.name != '' {
		if f is ast.SelectorExpr {
			e.stack << fun.recv
			e.local_ptrs[fun.f.recv.name] = e.stack.len - 1
		} else {
			e.error('invalid receiver for method call', f.pos)
		}
	}
	for i, arg in args {
		e.stack << arg
		e.local_ptrs[fun.f.args[i].name] = e.stack.len - 1
	}
	ret := e.stmts(fun.f.stmts)
	if !e.returning && fun.f.rets.len != 0 {
		e.error('no return statement', f.pos)
	}
	e.returning = false
	e.stack = e.stack[..e.stack.len - (args.len)]
	e.local_ptrs = {}
	e.local_ptrs = prev_ptrs.clone()
	if ret is Err {
		e.error('Exception: $ret', f.pos)
	}
	return ret
}

fn (mut e Eval) stmts(stmts ast.Block) Val {
	for i, stmt in stmts.stmts {
		ret := e.stmt(stmt)
		if e.returning || i == stmts.stmts.len - 1 {
			return ret
		}
	}
	panic('should not be reached')
}

fn (mut e Eval) stmt(stmt ast.Stmt) Val {
	match stmt {
		ast.AssignStmt {
			e.set(stmt.left, stmt.op, stmt.right)
			return Void{}
		}
		ast.Expr {
			return e.expr(stmt)
		}
		ast.EmptyStmt {
			e.error('empty statement', stmt.pos)
		}
		ast.FnStmt {
			e.error('function can only be top-level', stmt.pos)
		}
		ast.ImportStmt {
			e.error('import can only be top-level', stmt.pos)
		}
		ast.Struct {
			e.error('struct can only be top-level', stmt.pos)
		}
		ast.ReturnStmt {
			e.returning = true
			return e.expr(stmt.expr)
		}
		ast.ForIn {
			var := ast.Ident{
				name: stmt.var
			}
			iter := ast.Ident{
				name: stmt.iter
			}
			arr := e.expr(stmt.expr)
			if arr is Array {
				if arr.vals.len == 0 {
					return Void{}
				}
				if stmt.iter != '' {
					e.set_val(iter, .decl_assign, i64(0))
				}
				e.set_val(var, .decl_assign, arr.vals[0])
				for i, val in arr.vals {
					e.set_val(var, .assign, val)
					if stmt.iter != '' {
						e.set_val(iter, .plus_assign, i64(1))
					}
					if i == arr.vals.len - 1 {
						return e.stmts(stmt.stmts)
					}
					e.stmts(stmt.stmts)
					if e.breaking {
						break
					}
				}
			} else if arr is string {
				if arr.len == 0 {
					return Void{}
				}
				if stmt.iter != '' {
					e.set_val(iter, .decl_assign, i64(0))
				}
				e.set_val(var, .decl_assign, arr.runes()[0])
				for i, c in arr.runes() {
					e.set_val(var, .assign, c)
					e.set_val(iter, .plus_assign, i64(1))
					if i == arr.runes().len - 1 {
						return e.stmts(stmt.stmts)
					}
					e.stmts(stmt.stmts)
					if e.breaking {
						return Void{}
					}
				}
			} else {
				e.error('for-in loop must iterate over an array', stmt.pos)
			}
			panic('unreachable')
		}
		ast.ForInf {
			for {
				e.stmts(stmt.stmts)
				if e.breaking {
					break
				}
			}
			return Void{}
		}
		ast.ForInN {
			var := ast.Ident{
				name: stmt.var
			}
			e.set(var, .decl_assign, ast.IntegerLiteral{
				val: stmt.low
			})
			for {
				e.stmts(stmt.stmts)
				if e.breaking {
					break
				}
				e.set_val(var, .plus_assign, i64(1))
				if e.expr(var) as i64 == stmt.high.i64() {
					break
				}
			}
			return Void{}
		}
		ast.ForC {
			for _ := e.stmt(stmt.init); e.expr(stmt.cond) as bool; e.stmt(stmt.loop) {
				e.stmts(stmt.stmts)
				if e.breaking {
					break
				}
			}
			return Void{}
		}
	}
}

fn (mut e Eval) exprs(exprs []ast.Expr) []Val {
	mut vals := []Val{cap: exprs.len}
	for expr in exprs {
		vals << e.expr(expr)
	}
	return vals
}
