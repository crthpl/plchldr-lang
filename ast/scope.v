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

fn (mut s Scope) str() string {
	return 'ast.Scope{
	file: \'${s.file}\'
	vars:
${s.var_str()}
'
}

fn (mut s Scope) var_str() string {
	return if s.parent != unsafe { nil } {
		s.parent.var_str()
	} else {
		''
	} + '\n' + ' > ' + s.vars.keys().str()
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
	if scope.parent != unsafe { nil } {
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
