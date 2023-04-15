module ast

pub fn new_table() &Table {
	scope := new_scope(&Scope(0), -1, '[GLOBAL]')
	mut table := &Table{
		global_scope: scope
	}
	for name, typ in builtin_type_names {
		table.register_type(name, Builtin(typ))
	}
	table.register_info(Array{ of: Builtin.string })
	return table
}

[heap]
pub struct Table {
mut:
	syms []&TypeSym
pub mut:
	names        map[string]Type
	decls        map[string]map[string]&Stmt // module name -> decl name -> decl
	global_scope &Scope
}

// temp
pub fn (t Table) print_path_sep(str string) {
	println('${str}: os path sep ' + t.decls['os']['path_separator'] or {
		error('no os.path_separator')
	}.str())
}

[heap]
pub struct TypeSym {
pub:
	name string
	typ  Type
	info Info
pub mut:
	methods map[string]&FnStmt
}

pub fn (t TypeSym) str() string {
	return t.name
}

pub fn (mut t Table) register_info(info Info) Type {
	typ := t.syms.len
	t.syms << &TypeSym{
		name: info.str()
		typ: typ
		info: info
	}
	return typ
}

pub fn (t Table) check_syms() {
	for i, sym in t.syms {
		if sym.typ != i {
			panic('bad symbol table')
		}
	}
}

pub fn (mut t Table) register_type(name string, info Info) Type {
	typ := t.syms.len
	t.syms << &TypeSym{
		name: name
		typ: typ
		info: info
	}
	t.names[name] = typ
	return typ
}

pub fn (t Table) get_info(typ Type) Info {
	return t.syms[int(typ)].info
}

pub fn (t Table) get_sym(typ Type) &TypeSym {
	return t.syms[int(typ)]
}

// Register the type if it doesn't exist yet.
pub fn (mut t Table) wget_type(info Info) Type {
	return t.get_type(info) or { t.register_info(info) }
}

pub fn (t Table) get_type(info Info) ?Type {
	for sym in t.syms {
		if sym.info == info {
			return sym.typ
		}
	}
	return none
}

pub fn (t Table) find_type(name string) ?Type {
	return t.names[name] or { return none }
}

pub fn (mut t Table) register_method(on Type, name string, fn_stmt &FnStmt) ? {
	if name in t.syms[int(on)].methods {
		return error('duplicate method')
	}
	t.syms[int(on)].methods[name] = fn_stmt
}
