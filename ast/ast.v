module ast

import token

[heap]
pub struct File {
pub:
	filename string
	full_mod string
pub mut:
	scope   &Scope
	decls   []string
	methods []&FnStmt
	imports map[string]string // c -> a.b.c
}

pub struct Block {
pub:
	scope &Scope
pub mut:
	stmts []Stmt
}

pub type Stmt = AssignStmt
	| EmptyStmt
	| Enum
	| Expr
	| FnStmt
	| For
	| ForC
	| ForIn
	| ForInN
	| ForInf
	| ImportStmt
	| Label
	| ReturnStmt
	| Struct

pub struct AssignStmt {
pub:
	pos token.Pos
	op  token.Kind
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

pub struct EmptyStmt {
pub:
	pos token.Pos
}

pub fn empty_stmt(pos token.Pos) EmptyStmt {
	return EmptyStmt{
		pos: pos
	}
}

[heap]
pub struct FnStmt {
pub:
	pos        token.Pos
	is_method  bool
	file       &File
	full_mod   string
	short_name string
	name       string
	recv       FnArg
pub mut:
	stmts Block
	args  []FnArg
	rets  []Type
}

pub struct For {
pub:
	pos   token.Pos
	label string
pub mut:
	stmts Block
	expr  Expr
}

pub struct ForIn {
pub:
	pos   token.Pos
	var   string // a in `for a in b` or `for i, a in b`
	iter  string // i in `for i, a in b`
	label string
pub mut:
	stmts Block
	expr  Expr
}

pub struct ForInN {
pub:
	pos   token.Pos
	var   string
	low   string
	high  string
	label string
pub mut:
	stmts Block
}

pub struct ForInf {
pub:
	pos   token.Pos
	label string
pub mut:
	stmts Block
}

pub struct ForC {
pub:
	pos   token.Pos
	label string
pub mut:
	init  Stmt
	cond  Expr
	loop  Stmt
	stmts Block
}

pub struct ImportStmt {
pub:
	pos  token.Pos
	name string
	last string
}

pub struct ReturnStmt {
pub:
	pos token.Pos
pub mut:
	expr Expr
}

pub struct Label {
pub:
	pos   token.Pos
	label string
}

pub struct Struct {
pub:
	pos         token.Pos
	name        string
	field_names []string
	types       []Type
	embeds      []Type
}

pub struct FnArg {
pub:
	pos  token.Pos
	name string
	typ  Type
}

pub struct Enum {
pub:
	pos    token.Pos
	name   string
	fields []string
}

pub type Expr = ArrayInit
	| CallExpr
	| CastExpr
	| EmptyExpr
	| Ident
	| IfExpr
	| IndexExpr
	| InfixExpr
	| Literal
	| MapInit
	| MatchExpr
	| PrefixExpr
	| SelectorExpr
	| StructInit

pub type Literal = BoolLiteral | EnumLiteral | IntegerLiteral | RuneLiteral | StringLiteral

pub struct ArrayInit {
pub:
	pos   token.Pos
	elems []Expr
pub mut:
	typ       Type
	elem_type Type
}

pub struct BoolLiteral {
pub:
	pos token.Pos
	val bool
}

pub struct CallExpr {
pub:
	pos  token.Pos
	args []Expr
pub mut:
	left      Expr
	left_type Type
	typ       Type
}

pub struct CastExpr {
pub:
	pos token.Pos
pub mut:
	totyp   Type
	fromtyp Type
	expr    Expr
}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct EmptyExpr {
pub:
	pos token.Pos
}

pub struct EnumLiteral {
pub:
	pos   token.Pos
	field string
pub mut:
	typ Type
}

pub struct Ident {
pub:
	pos  token.Pos
	name string
}

pub struct IfExpr {
pub:
	pos token.Pos
pub mut:
	stmts Block
	cond  Expr
}

pub enum IndexType {
	index
	from
	to
	from_to
}

pub struct IndexExpr {
pub:
	pos token.Pos
	typ IndexType
pub mut:
	left    Expr
	index   Expr
	index2  Expr
	or_expr OrExpr
}

pub struct InfixExpr {
pub:
	pos token.Pos
	op  token.Kind
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

pub struct IntegerLiteral {
pub:
	pos token.Pos
	val string
}

pub struct MapInit {
pub:
	pos token.Pos
pub mut:
	left       []Expr
	right      []Expr
	left_type  Type
	right_type Type
	typ        Type
}

pub type MatchCond = Literal | Range

pub fn (m []MatchCond) pos() token.Pos {
	first := m.first()
	last := m.last()
	return match first {
		Literal {
			first.pos.extend(last.pos)
		}
		Range {
			first.pos.extend(last.pos)
		}
	}
}

pub struct Range {
pub:
	pos       token.Pos
	inclusive bool // true: [], false: [)
pub mut:
	from Literal
	to   Literal
}

pub struct MatchExpr {
pub:
	pos      token.Pos
	conds    [][]MatchCond
	has_else bool
pub mut:
	stmtss    []Block
	expr      Expr
	expr_type Type
}

pub struct PrefixExpr {
pub:
	pos token.Pos
	op  token.Kind
pub mut:
	right Expr
}

pub struct RuneLiteral {
pub:
	pos token.Pos
	val rune
}

pub struct SelectorExpr {
pub:
	pos token.Pos
	sel string
pub mut:
	left      Expr
	left_type Type
	typ       Type
}

pub struct StringLiteral {
pub:
	pos token.Pos
	val string
}

pub struct StructInit {
pub:
	pos   token.Pos
	typ   Type
	left  []Expr
	right []Expr
}

pub struct OrExpr {
pub:
	pos    token.Pos
	exists bool
	stmts  Block
pub mut:
	typ Type
}
