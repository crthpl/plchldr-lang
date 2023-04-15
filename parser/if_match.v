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
	mut conds := [][]ast.MatchCond{}
	mut stmtss := []ast.Block{}
	mut has_else := false
	for i := 0; p.tok.kind != .rcbr; i++ {
		if has_else {
			p.error('else must be the last branch of a match')
		}
		if p.tok.kind == .key_else {
			p.next()
			has_else = true
		} else {
			conds << p.match_cond()
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
		conds: conds
		stmtss: stmtss
		has_else: has_else
		pos: pos
	}
}

fn (mut p Parser) match_cond() []ast.MatchCond {
	mut conds := []ast.MatchCond{}
	for {
		pos := p.tok.Pos
		lit := p.literal()
		if p.tok.kind == .dotdotdot {
			p.next()
			end := p.literal()
			conds << ast.Range{
				pos: pos
				from: lit
				to: end
				inclusive: true
			}
		} else if p.tok.kind == .dotdot {
			p.next()
			end := p.literal()
			conds << ast.Range{
				pos: pos
				from: lit
				to: end
				inclusive: false
			}
		} else {
			conds << lit
		}
		match p.tok.kind {
			.comma {
				p.next()
				continue
			}
			.lcbr {
				return conds
			}
			else {
				p.error('unexpected $p.tok.kind, expecting comma or `{`')
			}
		}
	}
	panic('unreachable')
}
