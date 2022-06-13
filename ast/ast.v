module ast

import token

[heap]
pub struct File {
pub:
	filename string
	full_mod string
pub mut:
	decls   Block
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
	| Expr
	| FnStmt
	| ForC
	| ForIn
	| ForInN
	| ForInf
	| ImportStmt
	| ReturnStmt
	| Struct

pub struct AssignStmt {
pub:
	op  token.Kind
	pos token.Pos
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
	file       &File
	full_mod   string
	short_name string
	name       string
	recv       FnArg
	pos        token.Pos
pub mut:
	stmts Block
	args  []FnArg
	rets  []Type
}

pub struct ForIn {
pub:
	var  string // a in `for a in b` or `for i, a in b`
	iter string // i in `for i, a in b`
	pos  token.Pos
pub mut:
	stmts Block
	expr  Expr
}

pub struct ForInN {
pub:
	var  string
	low  string
	high string
	pos  token.Pos
pub mut:
	stmts Block
}

pub struct ForInf {
pub:
	pos token.Pos
pub mut:
	stmts Block
}

pub struct ForC {
pub:
	pos token.Pos
pub mut:
	init  Stmt
	cond  Expr
	loop  Stmt
	stmts Block
}

pub struct ImportStmt {
	name string
	last string
pub:
	pos token.Pos
}

pub struct ReturnStmt {
pub:
	pos token.Pos
pub mut:
	expr Expr
}

pub struct FnArg {
pub:
	pos  token.Pos
	name string
	typ  Type
}

pub struct Struct {
pub:
	name        string
	field_names []string
	types       []Type
	pos         token.Pos
}

pub type Expr = ArrayInit
	| BoolLiteral
	| CallExpr
	| EmptyExpr
	| Ident
	| IfExpr
	| IndexExpr
	| InfixExpr
	| IntegerLiteral
	| MatchExpr
	| PrefixExpr
	| RuneLiteral
	| SelectorExpr
	| StringLiteral
	| StructInit

pub struct ArrayInit {
pub:
	elems []Expr
	pos   token.Pos
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
	args []Expr
	pos  token.Pos
pub mut:
	left      Expr
	left_type Type
	typ       Type
}

pub fn empty_expr() Expr {
	return EmptyExpr{}
}

pub struct EmptyExpr {
pub:
	pos token.Pos
}

pub struct Ident {
pub:
	name string
	pos  token.Pos
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
	typ IndexType
	pos token.Pos
pub mut:
	left   Expr
	index  Expr
	index2 Expr
}

pub struct InfixExpr {
pub:
	op  token.Kind
	pos token.Pos
pub mut:
	left       Expr
	right      Expr
	left_type  Type
	right_type Type
}

pub struct IntegerLiteral {
pub:
	val string
	pos token.Pos
}

pub struct MatchExpr {
pub:
	bexprs []Expr
	elsei  int
	pos    token.Pos
pub mut:
	stmtss []Block
	expr   Expr
}

pub struct PrefixExpr {
pub:
	op  token.Kind
	pos token.Pos
pub mut:
	right Expr
}

pub struct RuneLiteral {
pub:
	val rune
	pos token.Pos
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
	val string
	pos token.Pos
}

pub struct StructInit {
pub:
	typ   Type
	left  []Expr
	right []Expr
	pos   token.Pos
}
