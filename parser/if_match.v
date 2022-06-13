module parser

import ast

fn (mut p Parser) if_expr() ast.IfExpr {
	pos := p.tok.Pos
	p.check(.key_if)
	cond := p.expr(0)
	p.open_scope()
	stmts := p.stmts()
	return ast.IfExpr{
		cond: cond
		stmts: ast.Block{
			stmts: stmts
			scope: p.close_scope()
		}
		pos: pos
	}
}

fn (mut p Parser) match_expr() ast.MatchExpr {
	pos := p.tok.Pos
	p.check(.key_match)
	expr := p.expr(0)
	p.check(.lcbr)
	mut bexprs := []ast.Expr{}
	mut stmtss := []ast.Block{}
	mut elsei := -1
	for i := 0; p.tok.kind != .rcbr; i++ {
		if p.tok.kind == .key_else {
			elsei = i
			p.next()
			bexprs << ast.empty_expr()
		} else {
			bexprs << p.expr(0)
		}
		p.open_scope()

		stmts := p.stmts()
		stmtss << ast.Block{
			stmts: stmts
			scope: p.close_scope()
		}
	}
	p.check(.rcbr)
	return ast.MatchExpr{
		expr: expr
		bexprs: bexprs
		stmtss: stmtss
		elsei: elsei
		pos: pos
	}
}
