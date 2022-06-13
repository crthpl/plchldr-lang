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

type Val = Array | Err | Function | Ptr | Struct | Void | bool | i64 | rune | string | u64

fn (v Val) str() string {
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
	}
}

fn (e Eval) get_type(v Val) ast.Type {
	return match v {
		Err {
			ast.err_type
		}
		Void {
			ast.void_type
		}
		i64 {
			ast.i64_type
		}
		rune {
			ast.rune_type
		}
		string {
			ast.string_type
		}
		bool {
			ast.bool_type
		}
		Array {
			e.table.get_type(v.sym.info) or { panic('invalid type') }
		}
		else {
			panic('todo! $v.type_name()')
		}
	}
}
