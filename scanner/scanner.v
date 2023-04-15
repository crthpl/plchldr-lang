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
				col++
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
				i++
				col++
				start := i
				start_col := col
				start_line := line
				for text[i] != `"` || (text[i] == `"` && text[i - 1] == `\\`) {
					i++
					col++
				}
				toks << token.Token{
					kind: .rune
					lit: text[start..i]
					i: start
					line: start_line
					col: start_col
				}
			}
			else {
				if text[i] == `/` && text[i + 1] == `/` {
					for text[i] != `\n` {
						i++
					}
					i--
					continue
				}
				for l := 3; l != 0; l-- {
					if i + l - 0 > text.len {
						continue
					}
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
				eprintln('error:$line:$col: unknown char: `${text[i].ascii_str()}`')
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
