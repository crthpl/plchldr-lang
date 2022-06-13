module parser

import token
import ast

fn (mut p Parser) stmt() ast.Stmt {
	match p.tok.kind {
		.key_fn {
			return p.fun()
		}
		.key_import {
			p.error('import statements are only allowed at the start of a file')
			for {
				p.check(.name)
				if p.tok.kind != .dot {
					break
				}
				p.next()
			}
			return ast.empty_stmt(p.tok.Pos)
		}
		.key_return {
			pos := p.tok.Pos
			p.next()
			expr := p.expr(0)
			return ast.ReturnStmt{
				expr: expr
				pos: pos
			}
		}
		.key_for {
			return p.for_loop()
		}
		.key_struct {
			return p.type_decl()
		}
		else {
			expr := p.expr(0)
			if p.tok.kind in token.assign {
				return p.right_assign_stmt(expr)
			}
			return expr
		}
	}
}

fn (mut p Parser) stmts() []ast.Stmt {
	p.check(.lcbr)
	mut stmts := []ast.Stmt{}
	for p.tok.kind != .rcbr {
		stmts << p.stmt()
	}
	p.check(.rcbr)
	return stmts
}

fn (mut p Parser) fn_arg() ast.FnArg {
	arg_pos := p.tok.Pos
	var := p.tok.lit
	p.check(.name)
	typ := p.parse_type()
	return ast.FnArg{
		name: var
		typ: typ
		pos: arg_pos
	}
}

fn (mut p Parser) fun() ast.FnStmt {
	pos := p.tok.Pos
	p.check(.key_fn)
	is_method := p.tok.kind == .lpar
	recv := if is_method {
		p.next()
		r := p.fn_arg()
		p.check(.rpar)
		r
	} else {
		ast.FnArg{}
	}
	short_name := p.tok.lit
	p.check(.name)
	p.check(.lpar)
	mut args := []ast.FnArg{}
	if p.tok.kind == .name {
		for {
			args << p.fn_arg()
			if p.tok.kind == .rpar {
				break
			}
			p.check(.comma)
		}
	}
	p.check(.rpar)
	mut rets := []ast.Type{}
	if p.is_type() {
		rets << p.parse_type()
		for p.tok.kind == .comma {
			p.next()
			rets << p.parse_type()
		}
	}
	p.open_scope()
	if recv.typ != 0 {
		p.scope.vars[recv.name] = &ast.Var{
			name: recv.name
			typ: recv.typ
			init: recv.pos
		}
	}
	for arg in args {
		p.scope.vars[arg.name] = &ast.Var{
			name: arg.name
			typ: arg.typ
			init: arg.pos
		}
	}
	name := p.full_mod + '.' + short_name
	stmts := p.stmts()
	f := ast.FnStmt{
		full_mod: p.full_mod
		short_name: short_name
		name: name
		args: args
		rets: rets
		stmts: ast.Block{
			stmts: stmts
			scope: p.close_scope()
		}
		recv: recv
		file: p.file
		pos: pos
	}
	if recv.typ != 0 {
		p.table.register_method(recv.typ, short_name, f) or { p.error('method already defined') }
	}
	p.table.fns[name] = &f
	return f
}

fn (mut p Parser) right_assign_stmt(left ast.Expr) ast.AssignStmt {
	op := p.tok.kind
	p.next()
	right := p.expr(0)
	match op {
		.decl_assign {
			if left is ast.Ident {
				p.scope.vars[left.name] = &ast.Var{
					name: left.name
					init: left.pos
				}
			}
			// else: checker error
		}
		else {}
	}
	return ast.AssignStmt{
		left: left
		op: op
		right: right
		pos: left.pos
	}
}

fn (mut p Parser) for_loop() ast.Stmt {
	pos := p.tok.Pos
	p.check(.key_for)
	if p.tok.kind == .lcbr {
		p.open_scope()
		stmts := p.stmts()
		return ast.ForInf{
			pos: pos
			stmts: ast.Block{
				stmts: stmts
				scope: p.close_scope()
			}
		}
	}
	var_pos := p.tok.Pos
	mut var := p.tok.lit
	p.check(.name)
	if p.tok.kind == .key_in && p.peek.kind == .num {
		p.next()
		low := p.tok.lit
		p.check(.num)
		p.check(.dotdot)
		high := p.tok.lit
		p.check(.num)
		p.open_scope()
		p.scope.vars[var] = &ast.Var{
			name: var
			typ: ast.i64_type
			init: var_pos
		}
		stmts := p.stmts()
		return ast.ForInN{
			pos: pos
			var: var
			low: low
			high: high
			stmts: ast.Block{
				stmts: stmts
				scope: p.close_scope()
			}
		}
	} else if p.tok.kind == .key_in || (p.tok.kind == .comma && p.peek.kind == .name) {
		mut iter := ''
		if p.tok.kind == .comma {
			iter = var
			p.next()
			var = p.tok.lit
			p.check(.name)
		}
		p.check(.key_in)
		expr := p.expr(0)
		p.open_scope()
		p.scope.vars[var] = &ast.Var{
			name: var
			init: var_pos
		}
		if iter != '' {
			p.scope.vars[iter] = &ast.Var{
				name: iter
				typ: ast.i64_type
				init: var_pos
			}
		}
		stmts := p.stmts()
		return ast.ForIn{
			pos: pos
			var: var
			iter: iter
			expr: expr
			stmts: ast.Block{
				stmts: stmts
				scope: p.close_scope()
			}
		}
	} else {
		p.back(1)
		p.open_scope()
		init := if p.tok.kind != .semi { p.stmt() } else { ast.EmptyStmt{} }
		p.check(.semi)
		cond := if p.tok.kind != .semi {
			p.expr(0)
		} else {
			ast.BoolLiteral{
				pos: p.tok.Pos
				val: true
			}
		}
		p.check(.semi)
		loop := if p.tok.kind != .lcbr { p.stmt() } else { ast.EmptyStmt{} }
		stmts := p.stmts()
		return ast.ForC{
			pos: pos
			init: init
			cond: cond
			loop: loop
			stmts: ast.Block{
				stmts: stmts
				scope: p.close_scope()
			}
		}
	}
}
