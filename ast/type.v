module ast

type Type = int

const (
	builtin_type_names = {
		'placeholder': Builtin.placeholder
		'void':        Builtin.void
		'i64':         Builtin.i64
		'u64':         Builtin.u64
		'bool':        Builtin.bool
		'rune':        Builtin.rune
		'string':      Builtin.string
		'err':         Builtin.err
	}
)

pub type Info = Array | Builtin | Enum | Map | Multi | Placeholder | Ptr | Struct

pub fn (i Info) str() string {
	match i {
		Array {
			return '[]' + i.of.str()
		}
		Enum {
			return 'enum $i.name { ' + i.fields.join(', ') + ' }'
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
		Placeholder {
			return 'placeholder(${string(i)})'
		}
		Ptr {
			return '&' + i.of.str()
		}
		Struct {
			return i.name
		}
		Map {
			return 'map[$i.left]$i.right'
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
	stringarr // workaround
}

pub fn (b Builtin) typ() Type {
	return Type(b)
}

pub struct Map {
pub:
	left  Info
	right Info
}

pub type Multi = []Info

pub type Placeholder = string

pub struct Ptr {
	of Info
}

pub fn (mut t Table) get_fn_type(fun &FnStmt) Type {
	return 999 // TODO
}
