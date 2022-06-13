module ast

import token

[heap]
pub struct Scope {
pub:
	file string
	from int
pub mut:
	parent   &Scope
	to       int
	children []&Scope
	vars     map[string]&Var
}

fn (s &Scope) str() string {
	mut vars := ''
	for curs := s; curs != voidptr(0); curs = curs.parent {
		vars = curs.vars.keys().str() + '\n' + vars
	}
	return 'ast.Scope{
	file: \'$s.file\'
	vars:
$vars}'
}

pub fn new_scope(parent &Scope, from int, file string) &Scope {
	return &Scope{
		file: file
		from: from
		parent: parent
	}
}

pub fn (scope &Scope) find_var(name string) ?&Var {
	if var := scope.vars[name] {
		return var
	}
	if scope.parent != voidptr(0) {
		return scope.parent.find_var(name)
	}
	return none
}

pub struct Var {
pub:
	name string
	init token.Pos
pub mut:
	typ Type
}
