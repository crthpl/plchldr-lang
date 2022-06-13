module eval

import ast
import token

fn (mut e Eval) lexpr(expr ast.Expr) &Val {
	match expr {
		ast.Ident {
			idx := e.local_ptrs[expr.name] or {
				e.error('undefined variable: `$expr.name.bytes()`', expr.pos)
			}
			if idx >= e.stack.len {
				e.error('corrupted stack; ptrs:{$e.local_ptrs}, stack:{$e.stack}', expr.pos)
			}
			return &e.stack[idx]
		}
		else {
			e.error('unexpected lexpr: $expr.type_name()', expr.pos)
		}
	}
}

fn (mut e Eval) set(left ast.Expr, op token.Kind, right ast.Expr) {
	e.set_rexpr(left, op, right, Void{})
}

fn (mut e Eval) set_val(left ast.Expr, op token.Kind, right Val) {
	e.set_rexpr(left, op, ast.empty_expr(), right)
}

fn (mut e Eval) set_rexpr(left ast.Expr, op token.Kind, right ast.Expr, _r Val) {
	r := if _r is Void {
		x := e.expr(right)
		if x is Void {
			e.error('assignment of void: $right', right.pos)
		}
		x
	} else {
		_r
	}
	match op {
		.assign {
			mut l := e.lexpr(left)
			unsafe {
				*l = r
			}
		}
		.decl_assign {
			if left is ast.Ident {
				if left.name in e.local_ptrs {
					e.error('redeclaration of `$left.name` $e.local_ptrs $e.stack | $left | $op | $right',
						left.pos)
				}
				e.stack << r
				e.local_ptrs[left.name] = e.stack.len - 1
			} else {
				e.error('left side of decl statement must be simple ident', left.pos)
			}
		}
		.plus_assign, .minus_assign, .mul_assign, .div_assign {
			mut l := e.lexpr(left)
			unsafe {
				match op {
					.plus_assign {
						*l = (*l as i64) + (r as i64)
					}
					.minus_assign {
						*l = (*l as i64) - (r as i64)
					}
					.mul_assign {
						*l = (*l as i64) * (r as i64)
					}
					.div_assign {
						*l = (*l as i64) / (r as i64)
					}
					else {
						panic('unreachable')
					}
				}
			}
		}
		.lsh {
			mut l := e.lexpr(left)
			if mut l is Array {
				l.vals << r
			} else {
				e.error('lsh assignment on non-array', left.pos)
			}
		}
		else {
			e.error('invalid assignment tok: $op', left.pos)
		}
	}
}
