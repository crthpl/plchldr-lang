module scanner

import os
import token

pub fn scan(file string) []token.Token {
	text := os.read_file(file) or { panic(err) }
	mut toks := []token.Token{}
	mut col := 0
	mut line := 1
	outer: for i := 0; i < text.len; i++ {
		col++
		match text[i] {
			`a`...`z`, `A`...`Z`, `_` {
				start := i
				start_col := col
				for (text[i] >= `a` && text[i] <= `z`)
					|| (text[i] >= `A` && text[i] <= `Z`)
					|| (text[i] >= `0` && text[i] <= `9`) || text[i] == `_` {
					i++
					col++
				}
				mut lit := text[start..i]
				kind := token.keywords[lit] or { token.Kind.name }
				if kind != .name {
					lit = ''
				}
				toks << token.Token{
					kind: kind
					lit: lit
					i: start
					line: line
					col: start_col
				}
				i--
				col--
			}
			` ` {}
			`\t` {
				col += 3
			}
			`\n` {
				col = 0
				line++
			}
			`'` {
				i++
				start := i
				start_col := col
				start_line := line
				for text[i] != `'` {
					i++
					col++
				}
				toks << token.Token{
					kind: .string
					lit: text[start..i]
					i: start
					line: start_line
					col: start_col
				}
			}
			`0`...`9` {
				start := i
				start_col := col
				for (text[i] >= `0` && text[i] <= `9`) {
					i++
					col++
				}
				lit := text[start..i]
				toks << token.Token{
					kind: .num
					lit: lit
					i: start
					line: line
					col: start_col
				}
				i--
			}
			`"` {
				i += 2
				col += 2
				toks << token.Token{
					kind: .rune
					lit: text[i - 1..i]
					i: i - 1
					line: line
					col: col - 1
				}
			}
			else {
				if text[i] == `/` && text[i + 1] == `/` {
					for text[i] != `\n` {
						i++
					}
					continue
				}
				for l := 2; l != 0; l-- {
					kind := token.operators[text[i..i + l]] or { continue }
					toks << token.Token{
						kind: kind
						i: i
						line: line
						col: col
					}
					i += l - 1
					continue outer
				}
				eprintln('error: unknown char: `${text[i].ascii_str()}`')
				exit(1)
			}
		}
	}
	toks << token.Token{
		kind: .eof
		i: text.len
		line: line
		col: col
	}
	toks << token.Token{
		kind: .eof
		i: text.len + 1
		line: line
		col: col
	}
	return toks
}
