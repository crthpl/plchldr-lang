module ast

pub type Type = int

pub const (
	void_type      = Type(1)
	i64_type       = Type(2)
	u64_type       = Type(3)
	bool_type      = Type(4)
	rune_type      = Type(5)
	string_type    = Type(6)
	err_type       = Type(7)
	stringarr_type = Type(8)
)

const (
	builtin_type_names = {
		'placeholder': 0
		'void':        void_type
		'i64':         i64_type
		'u64':         u64_type
		'bool':        bool_type
		'rune':        rune_type
		'string':      string_type
		'err':         err_type
	}
)

pub type Info = Array | Builtin | Multi | Ptr | Struct

pub fn (i Info) str() string {
	match i {
		Array {
			return '[]' + i.of.str()
		}
		Builtin {
			return i.str()
		}
		Multi {
			mut strs := []string{}
			for info in i {
				strs << info.str()
			}
			return '(' + strs.join(', ') + ')'
		}
		Ptr {
			return '&' + i.of.str()
		}
		Struct {
			return i.name
		}
	}
}

pub struct Alias {
pub:
	name string
	of   Info
}

pub struct Array {
pub:
	of Info
}

pub enum Builtin {
	placeholder = 0 // no type filled in
	void // no type, e.g. function that does not return anything
	i64
	u64
	bool
	rune
	string
	err
}

pub type Multi = []Info

pub struct Ptr {
	of Info
}

pub fn (mut t Table) get_fn_type(fun &FnStmt) Type {
	return 999 // TODO
}
