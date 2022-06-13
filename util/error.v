module util

import token

pub fn error(file string, token token.Pos, from string, msg string) {
	eprintln('$file:$token.line:$token.col: $from error: $msg')
}
