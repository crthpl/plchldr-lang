module eval

import ast
import token

fn (mut e Eval) expr(expr ast.Expr) Val {
	match expr {
		ast.ArrayInit {
			mut arr := []Val{cap: expr.elems.len}
			for elem in expr.elems {
				arr << e.expr(elem)
			}
			return Array{
				sym: e.table.get_sym(expr.typ)
				vals: arr
			}
		}
		ast.BoolLiteral {
			return expr.val
		}
		ast.CallExpr {
			// if expr.left is ast.SelectorExpr {
			//	if expr.left.left is ast.Ident {
			//		if expr.left.left in e.imports {
			//			return e.run_func(expr.left.left
			//	}
			//}
			return e.run_func(expr.left, ...e.exprs(expr.args))
		}
		ast.IfExpr {
			if e.expr(expr.cond) as bool {
				return e.stmts(expr.stmts)
			}
			return Void{}
		}
		ast.IntegerLiteral {
			return expr.val.i64()
		}
		ast.IndexExpr {
			left := e.expr(expr.left)
			if left is Array {
				index := e.expr(expr.index)
				match expr.typ {
					.index {
						return left.vals[index as i64]
					}
					.to {
						return Array{
							sym: left.sym
							vals: left.vals[..index as i64]
						}
					}
					.from {
						return Array{
							sym: left.sym
							vals: left.vals[index as i64..]
						}
					}
					.from_to {
						index2 := e.expr(expr.index2)
						return Array{
							sym: left.sym
							vals: left.vals[index as i64..index2 as i64]
						}
					}
				}
			}
			if left is string {
				index := e.expr(expr.index)
				match expr.typ {
					.index {
						return rune(left[index as i64])
					}
					.to {
						x := left[..index as i64]
						return x
					}
					.from {
						x := left[index as i64..]
						return x
					}
					.from_to {
						index2 := e.expr(expr.index2)
						x := left[index as i64..index2 as i64]
						return x
					}
				}
			}
			e.error('not an array', expr.pos)
		}
		ast.InfixExpr {
			return e.infix_expr(expr)
		}
		ast.EmptyExpr {
			e.error('empty expression', expr.pos)
		}
		ast.Ident {
			return e.stack[e.local_ptrs[expr.name] or {
				return e.global_vars['${e.file.full_mod}.$expr.name'] or {
					return Function{
						f: &(e.modules[e.file.full_mod][expr.name] or {
							e.error('undefined var: `$expr.name`', expr.pos)
						} as ast.FnStmt)
					}
				}
			}] or { e.error('corrupted stack: ptrs:{$e.local_ptrs}, stack:{$e.stack}', expr.pos) }
		}
		ast.MatchExpr {
			val := e.expr(expr.expr)
			for i, be in expr.bexprs {
				if i == expr.elsei {
					return e.stmts(expr.stmtss[i])
				}
				if e.expr(be) == val {
					return e.stmts(expr.stmtss[i])
				}
			}
			e.error('no else block!', expr.pos)
		}
		ast.PrefixExpr {
			val := e.expr(expr.right)
			match expr.op {
				.amp {
					return Ptr{
						val: &val
					}
				}
				.minus {
					return -(val as i64)
				}
				else {
					e.error('unknown prefix op: `$expr.op`', expr.pos)
				}
			}
		}
		ast.RuneLiteral {
			return expr.val
		}
		ast.SelectorExpr {
			if expr.left is ast.Ident {
				if full_mod := e.file.imports[expr.left.name] {
					if mod := e.modules[full_mod] {
						if fun := mod[expr.sel] {
							return Function{
								f: &(fun as ast.FnStmt)
							}
						} else {
							e.error('function `${expr.left.name}.$expr.sel` does not exist',
								expr.pos)
						}
					}
				}
			}
			return e.get_field(expr.left, expr.sel)
		}
		ast.StringLiteral {
			return expr.val
		}
		ast.StructInit {
			mut res := map[string]Val{}
			for i, left in expr.left {
				if left is ast.Ident {
					res[left.name] = e.expr(expr.right[i])
				} else {
					e.error('left side of struct init must be a name', left.pos)
				}
			}
			return Struct{
				sym: e.table.get_sym(expr.typ)
				fields: res
			}
		}
	}
	panic('unreachable $expr')
}

fn (mut e Eval) get_field(expr ast.Expr, field string) Val {
	left := e.expr(expr)
	if left is Array {
		match field {
			'len' { return i64(left.vals.len) }
			else { e.error('`$left.sym` does not have a field `$field`', expr.pos) }
		}
	}
	if left is Struct {
		if val := left.fields[field] {
			return val
		} else {
			if left.sym.info is ast.Struct {
				if field in left.sym.info.field_names {
					e.zero_val(left.sym.info.types[left.sym.info.field_names.index(field)])
				}
			} else {
				e.error('struct without struct info', expr.pos)
			}
		}
		e.error('`$left.sym` does not have a field `$field`', expr.pos)
	}

	if method := e.table.get_sym(e.get_type(left)).methods[field] {
		return Function{
			f: method
			recv: left
		}
	}
	e.error('`$expr` is not a struct', expr.pos)
}

fn (mut e Eval) zero_val(typ ast.Type) Val {
	e.error('zero_val not implemented', token.Pos{})
}

fn (mut e Eval) infix_expr(expr ast.InfixExpr) Val {
	match expr.op {
		.plus {
			return (e.expr(expr.left) as i64) + (e.expr(expr.right) as i64)
		}
		.minus {
			return (e.expr(expr.left) as i64) - (e.expr(expr.right) as i64)
		}
		.mul {
			return (e.expr(expr.left) as i64) * (e.expr(expr.right) as i64)
		}
		.div {
			return (e.expr(expr.left) as i64) / (e.expr(expr.right) as i64)
		}
		.eq {
			l := e.expr(expr.left)
			r := e.expr(expr.right)
			if e.get_type(l) != e.get_type(r) {
				e.error('equals type mismatch: `${e.get_type(l)}` != `${e.get_type(r)}` ($r)',
					expr.pos)
			}
			return l == r
		}
		.gt {
			l := e.expr(expr.left)
			r := e.expr(expr.right)
			if e.get_type(l) != e.get_type(r) {
				e.error('gt type mismatch: `${e.get_type(l)}` != `${e.get_type(r)}` ($r)',
					expr.pos)
			}
			if l is i64 {
				if r is i64 {
					return l > r
				} else {
					e.error('lt can only be used on integers', expr.pos)
				}
			} else {
				e.error('lt can only be used on integers', expr.pos)
			}
		}
		.lt {
			l := e.expr(expr.left)
			r := e.expr(expr.right)
			if e.get_type(l) != e.get_type(r) {
				e.error('lt type mismatch: `${e.get_type(l)}` != `${e.get_type(r)}` ($r)',
					expr.pos)
			}
			if l is i64 {
				if r is i64 {
					return l < r
				} else {
					e.error('lt can only be used on integers', expr.pos)
				}
			} else {
				e.error('lt can only be used on integers', expr.pos)
			}
		}
		.lsh {
			left := e.expr(expr.left)
			if left is i64 {
				return left << (e.expr(expr.right) as i64)
			} else if left is Array {
				e.set(expr.left, expr.op, expr.right)
				return Void{}
			} else {
				e.error('`<<` can only be used on integers and arrays', expr.pos)
			}
		}
		.rsh {
			return (e.expr(expr.left) as i64) >> (e.expr(expr.right) as i64)
		}
		else {
			e.error('unknown infix tok: $expr.op', expr.pos)
		}
	}
}
