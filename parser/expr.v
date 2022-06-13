module parser

import ast
import token

fn (mut p Parser) expr(prec int) ast.Expr {
	mut left := ast.empty_expr()
	left.str()
	match p.tok.kind {
		.name {
			if p.is_type() {
				left = p.with_type()
			} else {
				left = ast.Ident{
					name: p.tok.lit
					pos: p.tok.Pos
				}
				p.next()
			}
		}
		.lsbr {
			left = p.array()
		}
		.string {
			left = ast.StringLiteral{
				val: p.tok.lit
				pos: p.tok.Pos
			}
			p.next()
		}
		.rune {
			assert p.tok.lit.len == 1
			left = ast.RuneLiteral{
				val: p.tok.lit[0]
				pos: p.tok.Pos
			}
			p.next()
		}
		.num {
			left = ast.IntegerLiteral{
				val: p.tok.lit
				pos: p.tok.Pos
			}
			p.next()
		}
		.key_match {
			left = p.match_expr()
		}
		.amp, .minus {
			op := p.tok.kind
			if op == .amp && p.is_type() {
				left = p.with_type()
			} else {
				p.next()
				expr := p.expr(int(token.Prec.prefix))
				left = ast.PrefixExpr{
					op: op
					right: expr
					pos: p.prev.Pos
				}
			}
		}
		.key_if {
			left = p.if_expr()
		}
		else {
			p.error('unexpected `$p.tok.kind`')
		}
	}
	return p.expr_with_left(left, prec)
}

fn (mut p Parser) expr_with_left(left ast.Expr, prec int) ast.Expr {
	mut node := left
	for prec < p.tok.prec() {
		if p.tok.kind in token.infix {
			node = p.infix_expr(node)
		} else if p.tok.kind == .dot {
			pos := p.tok.Pos
			p.next()
			sel := p.tok.lit
			p.check(.name)
			node = ast.SelectorExpr{
				left: node
				sel: sel
				pos: pos
			}
		} else if p.tok.kind == .lpar {
			node = p.call_expr(node)
		} else if p.tok.kind == .lsbr {
			node = p.index_expr(node)
		} else {
			return node
		}
	}
	return node
}

fn (mut p Parser) infix_expr(left ast.Expr) ast.Expr {
	pos := p.tok.Pos
	op := p.tok.kind
	prec := p.tok.prec()
	p.next()
	right := p.expr(prec)
	return ast.InfixExpr{
		left: left
		right: right
		op: op
		pos: pos
	}
}

fn (mut p Parser) call_expr(left ast.Expr) ast.CallExpr {
	pos := p.tok.Pos
	p.check(.lpar)
	mut args := []ast.Expr{}
	if p.tok.kind != .rpar {
		for {
			args << p.expr(0)
			if p.tok.kind == .rpar {
				break
			}
			p.check(.comma)
		}
	}
	p.check(.rpar)
	return ast.CallExpr{
		left: left
		args: args
		pos: pos
	}
}

fn (mut p Parser) array() ast.ArrayInit {
	pos := p.tok.Pos
	a := p.is_type()
	typ := if a { p.parse_type() } else { 0 }
	p.check(.lsbr)
	mut elems := []ast.Expr{}
	if p.tok.kind != .rsbr {
		for {
			elems << p.expr(0)
			if p.tok.kind == .rsbr {
				break
			}
			p.check(.comma)
		}
	}
	p.check(.rsbr)
	return ast.ArrayInit{
		typ: typ
		elems: elems
		pos: pos
	}
}

fn (mut p Parser) index_expr(left ast.Expr) ast.IndexExpr {
	pos := p.tok.Pos
	p.check(.lsbr)
	mut typ := ast.IndexType.index
	if p.tok.kind == .colon {
		p.next()
		typ = .to
	}
	expr := p.expr(0)
	if p.tok.kind == .colon {
		p.next()
		typ = .from
	}
	mut expr2 := ast.empty_expr()
	if p.tok.kind != .rsbr {
		if typ == .from {
			expr2 = p.expr(0)
			typ = .from_to
		}
	}
	p.check(.rsbr)
	return ast.IndexExpr{
		left: left
		index: expr
		index2: expr2
		typ: typ
		pos: pos
	}
}

fn (mut p Parser) struct_init() ast.StructInit {
	pos := p.tok.Pos
	typ := p.parse_type()
	p.check(.lcbr)
	mut left := []ast.Expr{}
	mut right := []ast.Expr{}
	for p.tok.kind != .rcbr {
		left << p.expr(0)
		p.check(.colon)
		right << p.expr(0)
	}
	p.check(.rcbr)
	return ast.StructInit{
		typ: typ
		left: left
		right: right
		pos: pos
	}
}
