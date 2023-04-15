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
						typs = fun.rets.clone()
					} else if btyps := eval.builtin_rets[name] {
						typs = btyps.clone()
					} else {
						c.error(expr.pos, 'undefined function: ${name}')
					}
				}
				ast.SelectorExpr {
					name := expr.left.sel
					if mut expr.left.left is ast.Ident {
						if impor := c.file.imports[expr.left.left.name] {
							if fun := c.find_fn(impor + '.' + name) {
								typs = fun.rets.clone()
							} else {
								c.error(expr.pos, 'undefined function: ${impor}.${name}')
							}
						}
					} else {
						typ := c.expr(mut expr.left.left)
						sym := c.table.get_sym(typ)
						if meth := sym.methods[name] {
							typs = meth.rets.clone()
						} else {
							c.error(expr.pos, 'undefined method: ${*sym}.${name}')
						}
					}
				}
				else {
					println('help :(')
				}
			}
			expr.typ = match typs.len {
				0 {
					ast.Builtin.void.typ()
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
		ast.CastExpr {
			expr.fromtyp = c.expr(mut expr.expr)
			return expr.totyp
		}
		ast.EmptyExpr {
			c.error(expr.pos, 'invalid expression')
			return c.expecting_type
		}
		ast.Ident {
			if var := c.scope.find_var(expr.name) {
				if expr.name == 'path_separator' {
					println('var_typ: ${var.typ} [${c.scope}]')
				}
				return var.typ
			}
			if fun := c.find_fn(c.file.full_mod + '.' + expr.name) {
				return c.table.get_fn_type(fun)
			}
			if expr.name in eval.builtins {
				return ast.Builtin.void.typ()
			}
			c.error(expr.pos, 'undefined ident: ${expr.name}')
			return ast.Builtin.void.typ()
		}
		ast.IfExpr {
			typ := c.expr(mut expr.cond)
			if typ != ast.Builtin.bool.typ() {
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
						ast.Builtin.rune.typ()
					} else {
						c.error(expr.pos, 'indexing non-array type `${left}`')
						ast.Builtin.void.typ()
					}
				}
				else {
					c.error(expr.pos, 'indexing non-array type `${left}`')
					ast.Builtin.void.typ()
				}
			}
			return if expr.typ == .index { index_type } else { left_type }
		}
		ast.InfixExpr {
			expr.left_type = c.expr(mut expr.left)
			c.expecting_type = expr.left_type
			expr.right_type = c.expr(mut expr.right)
			if expr.left_type != expr.right_type && expr.op != .lsh {
				c.error(expr.pos, 'right: ${expr.right_type} ${expr.right} | mismatched types: ${*c.table.get_sym(expr.left_type)} and ${*c.table.get_sym(expr.right_type)}')
			}
			// println('$expr.pos: $expr.op')
			if expr.op in [.eq, .neq, .log_or, .and, .gt, .lt] {
				return ast.Builtin.bool.typ()
			}
			return expr.left_type
		}
		ast.MapInit {
			assert expr.left.len == expr.right.len
			for i, mut left in expr.left {
				if i == 0 {
					expr.left_type = c.expr(mut left)
					c.expecting_type = expr.left_type
				} else {
					typ := c.expr(mut left)
					if typ != expr.left_type {
						c.error(left.pos, 'mismatched types: ${*c.table.get_sym(expr.left_type)} and ${*c.table.get_sym(typ)}')
					}
				}
			}
			for i, mut right in expr.right {
				if i == 0 {
					expr.right_type = c.expr(mut right)
				} else {
					typ := c.expr(mut right)
					if typ != expr.right_type {
						c.error(right.pos, 'mismatched types: ${*c.table.get_sym(expr.right_type)} and ${*c.table.get_sym(typ)}')
					}
				}
			}
			expr.typ = c.table.wget_type(ast.Map{
				left: c.table.get_info(expr.left_type)
				right: c.table.get_info(expr.right_type)
			})
			return expr.typ
		}
		ast.MatchExpr {
			expr.expr_type = c.expr(mut expr.expr)
			for mut cond in expr.conds {
				typ := c.match_cond(mut cond)
				if typ != expr.expr_type {
					c.error(cond.pos(), 'mismatched types: ${*c.table.get_sym(expr.expr_type)} and ${*c.table.get_sym(typ)}')
				}
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
					c.error(expr.pos, 'invalid prefix operator: `${expr.op}`')
					return ast.Builtin.void.typ()
				}
			}
		}
		ast.SelectorExpr {
			if expr.left is ast.Ident && (expr.left as ast.Ident).name in c.file.imports {
				c.error(expr.pos, 'todo: module stuff')
			} else {
				expr.left_type = c.expr(mut expr.left)
			}
			left_info := c.table.get_info(expr.left_type)
			unknown_error := 'unknown field: ${left_info}.${expr.sel}'
			mut found := false
			if left_info is ast.Array {
				if expr.sel == 'len' {
					expr.typ = ast.Builtin.u64.typ()
				}
			}
			if !found && left_info is ast.Builtin {
				if left_info == .string {
					if expr.sel == 'len' {
						found = true
						expr.typ = ast.Builtin.u64.typ()
					}
				}
			}
			if !found && left_info is ast.Struct {
				index := left_info.field_names.index(expr.sel)
				if index != -1 {
					found = true
					expr.typ = left_info.types[index]
				}
			}
			if !found {
				left_sym := c.table.get_sym(expr.left_type)
				if method := left_sym.methods[expr.sel] {
					found = true
					expr.typ = c.table.get_fn_type(method)
				}
			}
			if !found {
				c.error(expr.pos, unknown_error)
			}
			return expr.typ
		}
		ast.StructInit {
			return expr.typ
		}
		ast.Literal {
			match mut expr {
				ast.BoolLiteral {
					return ast.Builtin.bool.typ()
				}
				ast.EnumLiteral {
					if expr.typ == 0 {
						expr.typ = c.expecting_type
						if expr.typ == ast.Builtin.void.typ() {
							c.error(expr.pos, 'cannot auto-detect enum type')
						}
						if expr.typ == 0 {
							panic('hlep :(')
						}
					}
					info := c.table.get_info(expr.typ)
					if info is ast.Enum {
						if expr.field !in info.fields {
							c.error(expr.pos, 'non existant enum field `${expr.field}` of `${info}`')
						}
					} else if info is ast.Placeholder {
						expr.typ = c.plchldr(info)
					} else {
						c.error(expr.pos, '`${info}` is not an enum')
					}
					return expr.typ
				}
				ast.IntegerLiteral {
					return ast.Builtin.i64.typ()
				}
				ast.RuneLiteral {
					return ast.Builtin.rune.typ()
				}
				ast.StringLiteral {
					return ast.Builtin.string.typ()
				}
			}
		}
	}
}

fn (mut c Checker) match_cond(mut conds []ast.MatchCond) ast.Type {
	mut global_typ := ast.Builtin.void.typ()
	for i, mut cond in conds {
		mut typ := 0
		match mut cond {
			ast.Range {
				from := c.expr(mut cond.from)
				to := c.expr(mut cond.to)
				if from != to {
					c.error(cond.pos, 'mismatched types: ${*c.table.get_sym(from)} and ${*c.table.get_sym(to)}')
				}
				typ = to
			}
			ast.Literal {
				typ = c.expr(mut cond)
			}
		}
		if i == 0 {
			global_typ = typ
		}
		if typ != global_typ {
			c.error(cond.pos, 'mismatched types: ${*c.table.get_sym(typ)} and ${*c.table.get_sym(global_typ)}')
		}
	}
	return global_typ
}
