module eval

import ast

struct Void {}

type Err = string

type Object = Val | ast.FnStmt

struct Ptr {
	val &Val
}

struct Struct {
	sym    ast.TypeSym
	fields map[string]Val
}

struct Array {
mut:
	sym  ast.TypeSym
	vals []Val
}

struct Function {
	sym  ast.TypeSym
	f    &ast.FnStmt
	recv Val
}

struct Map {
mut:
	sym     ast.TypeSym
	entries []MapEntry
}

struct Enum {
	sym ast.TypeSym
	val u64
}

struct MapEntry {
mut:
	left  Val
	right Val
}

type Val = Array
	| Enum
	| Err
	| Function
	| Map
	| Ptr
	| Struct
	| Void
	| bool
	| i64
	| rune
	| string
	| u64

fn (v Val) str() string {
	if v is Map {
		return '$v.sym{\n' + v.entries.map('\t$it.left.str(): $it.right.str()').join('\n') + '\n}'
	}
	return match v {
		Err {
			'runtime: $v.str()'
		}
		Void {
			'void'
		}
		rune {
			v.str()
		}
		i64 {
			v.str()
		}
		u64 {
			v.str()
		}
		string {
			v
		}
		bool {
			v.str()
		}
		Array {
			v.sym.str() + v.vals.str()
		}
		Function {
			'[todo fn str] fn $v.f.name ($v.f.args)'
		}
		Ptr {
			'&' + (*v.val).str()
		}
		Struct {
			v.sym.str() + v.fields.str()
		}
		Enum {
			'${v.sym}.${(v.sym.info as ast.Enum).fields[v.val]}'
		}
		else {
			panic('no string for eval.Val')
		}
	}
}

fn (e Eval) get_type(v Val) ast.Type {
	return match v {
		Err {
			ast.Builtin.err.typ()
		}
		Void {
			ast.Builtin.void.typ()
		}
		i64 {
			ast.Builtin.i64.typ()
		}
		rune {
			ast.Builtin.rune.typ()
		}
		string {
			ast.Builtin.string.typ()
		}
		bool {
			ast.Builtin.bool.typ()
		}
		Array {
			e.table.get_type(v.sym.info) or { panic('invalid type') }
		}
		else {
			panic('todo! $v.type_name()')
		}
	}
}
