module checker

import ast
import eval

fn (mut c Checker) expr(mut expr ast.Expr) ast.Type {
	match mut expr {
		ast.ArrayInit {
			mut elem_type := 0
			for i, mut elem in expr.elems {
				if i == 0 {
					elem_type = c.expr(mut elem)
				} else {
					c.expr(mut elem)
				}
			}
			typ := c.table.wget_type(ast.Array{ of: c.table.get_info(elem_type) })
			expr.typ = typ
			return expr.typ
		}
		ast.BoolLiteral {
			return ast.bool_type
		}
		ast.CallExpr {
			expr.left_type = c.expr(mut expr.left)
			for mut arg in expr.args {
				c.expr(mut arg)
			}
			mut typs := []ast.Type{}
			match mut expr.left {
				ast.Ident {
					name := expr.left.name

					if fun := c.find_fn(c.file.full_mod + '.' + name) {
						typs = fun.rets
					} else if btyps := eval.builtin_rets[name] {
						typs = btyps.clone()
					} else {
						c.error(expr.pos, 'undefined function: $name')
					}
				}
				ast.SelectorExpr {
					name := expr.left.sel
					if mut expr.left.left is ast.Ident {
						if impor := c.file.imports[expr.left.left.name] {
							if fun := c.find_fn(impor + '.' + name) {
								typs = fun.rets
							} else {
								c.error(expr.pos, 'undefined function: ${impor}.$name')
							}
						}
					} else {
						typ := c.expr(mut expr.left.left)
						sym := c.table.get_sym(typ)
						if meth := sym.methods[name] {
							typs = meth.rets
						} else {
							c.error(expr.pos, 'undefined method: ${*sym}.$name')
						}
					}
				}
				else {
					println('help :(')
				}
			}
			expr.typ = match typs.len {
				0 {
					ast.void_type
				}
				1 {
					typs[0]
				}
				else {
					c.table.wget_type(ast.Multi(typs.map(c.table.get_info(it))))
				}
			}
			return expr.typ
		}
		ast.EmptyExpr {
			c.error(expr.pos, 'invalid expression')
			return c.expecting_type
		}
		ast.Ident {
			if var := c.scope.find_var(expr.name) {
				return var.typ
			}
			if fun := c.find_fn(c.file.full_mod + '.' + expr.name) {
				return c.table.get_fn_type(fun)
			}
			if expr.name in eval.builtins {
				return ast.void_type
			}
			c.error(expr.pos, 'undefined ident: $expr.name')
			return ast.void_type
		}
		ast.IfExpr {
			typ := c.expr(mut expr.cond)
			if typ != ast.bool_type {
				c.error(expr.pos, 'condition must be a boolean, got ${*c.table.get_sym(typ)}')
			}
			return c.stmts(mut expr.stmts)
		}
		ast.IndexExpr {
			c.expr(mut expr.index)
			left_type := c.expr(mut expr.left)
			left := c.table.get_info(left_type)

			index_type := match left {
				ast.Array {
					c.table.get_type(left.of) or { panic('array type not found') }
				}
				ast.Builtin {
					if left == .string {
						ast.rune_type
					} else {
						c.error(expr.pos, 'indexing non-array type `$left`')
						ast.void_type
					}
				}
				else {
					c.error(expr.pos, 'indexing non-array type `$left`')
					ast.void_type
				}
			}
			return if expr.typ == .index { index_type } else { left_type }
		}
		ast.InfixExpr {
			expr.left_type = c.expr(mut expr.left)
			c.expecting_type = expr.left_type
			expr.right_type = c.expr(mut expr.right)
			if expr.left_type != expr.right_type && expr.op != .lsh {
				c.error(expr.pos, 'mismatched types: ${*c.table.get_sym(expr.left_type)} and ${*c.table.get_sym(expr.right_type)}')
			}
			// println('$expr.pos: $expr.op')
			if expr.op in [.eq, .neq, .log_or, .and, .gt, .lt] {
				return ast.bool_type
			}
			return expr.left_type
		}
		ast.IntegerLiteral {
			if c.expecting_type == ast.i64_type {
				return c.expecting_type
			}
			return ast.i64_type
		}
		ast.MatchExpr {
			c.expr(mut expr.expr)
			for mut be in expr.bexprs {
				c.expr(mut be)
			}
			mut ret := ast.Type(0)
			for mut stmts in expr.stmtss {
				ret = c.stmts(mut stmts)
			}
			return ret
		}
		ast.PrefixExpr {
			of := c.expr(mut expr.right)
			match expr.op {
				.amp {
					return c.table.wget_type(ast.Ptr{ of: c.table.get_info(of) })
				}
				.minus {
					return of
				}
				else {
					c.error(expr.pos, 'invalid prefix operator: `$expr.op`')
					return ast.void_type
				}
			}
		}
		ast.RuneLiteral {
			return ast.rune_type
		}
		ast.SelectorExpr {
			if !(expr.left is ast.Ident && (expr.left as ast.Ident).name in c.file.imports) {
				expr.left_type = c.expr(mut expr.left)
			}
			// todo: structs
			return ast.void_type
		}
		ast.StringLiteral {
			return ast.string_type
		}
		ast.StructInit {
			return expr.typ
		}
	}
}
