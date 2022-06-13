module parser

import ast

fn (mut p Parser) is_type() bool {
	return p.type_dist(-2) != -10
}

fn (mut p Parser) type_dist(idx int) int {
	peek := p.peek(idx)
	match peek.kind {
		.name {
			if peek.lit[0].is_capital() {
				return idx + 1
			}
			a := peek.lit in p.table.names
			if a {
				return idx + 1
			}
			if peek.lit in p.file.imports && p.peek(idx + 1).kind == .dot {
				return p.type_dist(idx + 2)
			}
			return -10
		}
		.lsbr {
			if p.peek(idx + 1).kind == .rsbr {
				return p.type_dist(idx + 2)
			}
			return -10
		}
		.amp {
			return p.type_dist(idx + 1)
		}
		else {
			return -10
		}
	}
}

fn (mut p Parser) type_decl() ast.Stmt {
	match p.tok.kind {
		.key_struct {
			pos := p.tok.Pos
			p.check(.key_struct)
			name := p.tok.lit
			p.check(.name)
			p.check(.lcbr)
			mut field_names := []string{}
			mut types := []ast.Type{}
			for p.tok.kind != .rcbr {
				field_names << p.tok.lit
				p.check(.name)
				types << p.parse_type()
			}
			p.check(.rcbr)
			s := ast.Struct{
				name: name
				field_names: field_names
				types: types
				pos: pos
			}
			p.table.register_type(p.full_mod + '.' + name, s)
			return s
		}
		else {
			p.error('invalid type_decl call')
			return ast.empty_stmt(p.tok.Pos)
		}
	}
}

fn (mut p Parser) with_type() ast.Expr {
	dist := p.type_dist(-2)
	if dist == -10 {
		p.error('with_type called without type')
	}
	match p.peek(dist).kind {
		.lsbr {
			return p.array()
		}
		.lcbr {
			return p.struct_init()
		}
		else {
			p.error('unexpected `${p.peek(dist).kind}` after type')
			return ast.empty_expr()
		}
	}
}

fn (mut p Parser) parse_type() ast.Type {
	match p.tok.kind {
		.name {
			if p.tok.lit in p.file.imports && p.peek.kind == .dot {
				mod := p.file.imports[p.tok.lit]
				p.check(.name)
				p.check(.dot)
				name := p.tok.lit
				p.check(.name)
				return p.table.find_type('${mod}.$name') or {
					p.error('unknown type: ${mod}.$name')
				}
			} else {
				p.check(.name)
				return p.table.find_type('${p.full_mod}.$p.prev.lit') or {
					p.table.find_type('$p.prev.lit') or { p.error('unknown type: $p.prev.lit') }
				}
			}
		}
		.amp {
			p.next()
			return p.table.wget_type(ast.Ptr{
				of: p.table.get_info(p.parse_type())
			})
		}
		.lsbr {
			p.next()
			p.check(.rsbr)
			return p.table.wget_type(ast.Array{
				of: p.table.get_info(p.parse_type())
			})
		}
		else {}
	}
	p.error('invalid type: `$p.tok.kind`')
	return ast.void_type
}
