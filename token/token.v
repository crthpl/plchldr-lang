module token

pub struct Token {
	Pos
pub:
	kind Kind
	lit  string
}

pub struct Pos {
pub:
	i    int
	line int
	col  int
	len  int
}

pub fn (p Pos) extend(p2 Pos) Pos {
	return Pos{
		i: p.i
		line: p.line
		col: p.col
		len: p2.i - p.i + p2.len
	}
}

pub enum Prec {
	lowest
	cond_low // ||
	cond_high // &&
	comp // ==, !=
	sum // + -
	product // * /
	prefix // &
	call // . (
	index // [
}

const (
	precs = {
		Kind.and:    Prec.cond_high
		Kind.log_or: Prec.cond_low
		Kind.eq:     Prec.comp
		Kind.neq:    Prec.comp
		Kind.gt:     Prec.comp
		Kind.lt:     Prec.comp
		Kind.geq:    Prec.comp
		Kind.leq:    Prec.comp
		Kind.plus:   Prec.sum
		Kind.minus:  Prec.sum
		Kind.mul:    Prec.product
		Kind.div:    Prec.product
		Kind.lsh:    Prec.product
		Kind.rsh:    Prec.product
		Kind.dot:    Prec.call
		Kind.lpar:   Prec.call
		Kind.lsbr:   Prec.index
	}
)

pub fn (t Token) prec() int {
	return int(token.precs[t.kind])
}

pub enum Kind {
	invalid
	eof
	name
	string
	num
	rune
	// two-sided ops
	lcbr
	rcbr
	lsbr
	rsbr
	lpar
	rpar
	// misc ops
	comma
	colon
	semi
	dot
	dotdot
	dotdotdot
	// math ops
	plus
	minus
	mul
	div
	// bitwise ops
	lsh
	rsh
	amp
	// assignment ops
	decl_assign
	assign
	plus_assign
	minus_assign
	mul_assign
	div_assign
	// comparison ops
	eq
	neq
	gt
	lt
	geq
	leq
	// bool ops
	and
	log_or
	// keywords
	key_else
	key_enum
	key_fn
	key_for
	key_if
	key_import
	key_in
	key_map
	key_match
	key_or
	key_return
	key_struct
}

pub const (
	operators = {
		'{':   Kind.lcbr
		'}':   Kind.rcbr
		'[':   Kind.lsbr
		']':   Kind.rsbr
		'(':   Kind.lpar
		')':   Kind.rpar
		',':   Kind.comma
		':':   Kind.colon
		';':   Kind.semi
		'.':   Kind.dot
		'..':  Kind.dotdot
		'...': Kind.dotdotdot
		'+':   Kind.plus
		'-':   Kind.minus
		'*':   Kind.mul
		'/':   Kind.div
		'<<':  Kind.lsh
		'>>':  Kind.rsh
		'&':   Kind.amp
		':=':  Kind.decl_assign
		'=':   Kind.assign
		'+=':  Kind.plus_assign
		'-=':  Kind.minus_assign
		'*=':  Kind.mul_assign
		'/=':  Kind.div_assign
		'==':  Kind.eq
		'!=':  Kind.neq
		'>':   Kind.gt
		'<':   Kind.lt
		'>=':  Kind.geq
		'<=':  Kind.leq
		'&&':  Kind.and
		'||':  Kind.log_or
	}
	infix    = [Kind.plus, .minus, .mul, .div, .eq, .neq, .gt, .lt, .geq, .leq, .lsh, .rsh, .and,
		.log_or]
	assign   = [Kind.decl_assign, .assign, .plus_assign, .minus_assign, .mul_assign, .div_assign]
	keywords = {
		'else':   Kind.key_else
		'enum':   Kind.key_enum
		'fn':     Kind.key_fn
		'for':    Kind.key_for
		'if':     Kind.key_if
		'import': Kind.key_import
		'in':     Kind.key_in
		'map':    Kind.key_map
		'match':  Kind.key_match
		'or':     Kind.key_or
		'return': Kind.key_return
		'struct': Kind.key_struct
	}
)
