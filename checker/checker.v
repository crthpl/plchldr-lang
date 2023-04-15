module checker

import token
import ast
import util

struct Checker {
mut:
	table          &ast.Table
	scope          &ast.Scope
	file           &ast.File
	expecting_type ast.Type
	errors         bool
}

pub fn check(mut file ast.File, table &ast.Table) bool {
	mut c := Checker{
		table: table
		file: file
		scope: file.scope
	}
	for name in file.decls {
		if name == 'path_separator' {
			println('checking ${name} ')
			table.print_path_sep('loop in check()')
		}
		c.stmt(mut c.table.decls[c.file.full_mod][name] or { panic('could not find declaration') })
	}
	for mut method in file.methods {
		c.fn_stmt(mut method)
	}
	return c.errors
}

fn (mut c Checker) error(pos token.Pos, err string) {
	util.error(c.file.filename, pos, 'checker', err)
	c.errors = true
}

fn (mut c Checker) stmts(mut stmts ast.Block) ast.Type {
	old_scope := c.scope
	defer {
		c.scope = old_scope
	}
	c.scope = stmts.scope
	for i, mut stmt in stmts.stmts {
		if i == stmts.stmts.len - 1 {
			return c.stmt(mut stmt)
		} else {
			c.stmt(mut stmt)
		}
	}
	if stmts.stmts.len != 0 {
		panic('unreachable')
	}
	return ast.Builtin.void.typ()
}

fn (mut c Checker) stmt(mut stmt ast.Stmt) ast.Type {
	c.expecting_type = 0
	match mut stmt {
		ast.AssignStmt {
			if mut stmt.left is ast.Ident {
				println('assigning to ${stmt.left.name}')
			}
			if stmt.op == .decl_assign {
				stmt.right_type = c.expr(mut stmt.right)
				c.expecting_type = stmt.right_type
				stmt.left_type = c.expr(mut stmt.left)
				assert stmt.left_type in [0, 1]
				info := c.table.get_info(stmt.right_type)
				if info is ast.Placeholder {
					stmt.right_type = c.plchldr(info)
				}
				stmt.left_type = stmt.right_type
				if mut stmt.left is ast.Ident {
					mut var := c.scope.find_var(stmt.left.name) or {
						panic('decl assign variable not found in ${c.scope}')
					}
					if var.typ != 0 {
						c.error(stmt.left.pos, 'redecleration of variable `${stmt.left.name}`')
					}
					var.typ = stmt.left_type
				} else {
					c.error(stmt.left.pos, 'cannot assign to `${stmt.left}`')
				}
			} else {
				stmt.left_type = c.expr(mut stmt.left)
				c.expecting_type = stmt.left_type
				stmt.right_type = c.expr(mut stmt.right)
			}
			if stmt.left_type != stmt.right_type && stmt.op != .decl_assign {
				c.error(stmt.pos, 'assignment mismatch')
			}
			return ast.Builtin.void.typ()
		}
		ast.Expr {
			return c.expr(mut stmt)
		}
		ast.EmptyStmt {
			c.error(stmt.pos, 'invalid empty statement')
			return ast.Builtin.void.typ()
		}
		ast.ImportStmt {
			return ast.Builtin.void.typ()
		}
		ast.ReturnStmt {
			return c.expr(mut stmt.expr)
		}
		ast.FnStmt {
			return c.fn_stmt(mut stmt)
		}
		ast.For {
			c.stmts(mut stmt.stmts)
			return ast.Builtin.void.typ()
		}
		ast.ForIn {
			c.expr(mut stmt.expr)
			c.stmts(mut stmt.stmts)
			return ast.Builtin.void.typ()
		}
		ast.ForInf {
			c.stmts(mut stmt.stmts)
			return ast.Builtin.void.typ()
		}
		ast.ForInN {
			c.stmts(mut stmt.stmts)
			return ast.Builtin.void.typ()
		}
		ast.ForC {
			old_scope := c.scope
			defer {
				c.scope = old_scope
			}
			c.scope = stmt.stmts.scope
			c.stmt(mut stmt.init)
			cond := c.expr(mut stmt.cond)
			if cond != ast.Builtin.bool.typ() {
				c.error(stmt.cond.pos, 'for condition must be a boolean')
			}
			c.stmt(mut stmt.loop)
			c.stmts(mut stmt.stmts)
			return ast.Builtin.void.typ()
		}
		ast.Label {
			return ast.Builtin.void.typ()
		}
		ast.Struct {
			return ast.Builtin.void.typ()
		}
		ast.Enum {
			return ast.Builtin.void.typ()
		}
	}
}

fn (mut c Checker) fn_stmt(mut fun ast.FnStmt) ast.Type {
	c.stmts(mut fun.stmts)
	return ast.Builtin.void.typ()
}

fn (c Checker) find_fn(name string) ?ast.FnStmt {
	if decl := c.table.decls[c.file.full_mod][name] {
		if decl is ast.FnStmt {
			return decl
		}
	}
	return none
}
