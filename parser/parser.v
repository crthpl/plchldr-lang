module parser

import ast
import token
import scanner
import util
import os

struct Parser {
mut:
	table    &ast.Table
	filename string
	mod      string
	full_mod string
	file     &ast.File
	toks     []token.Token
	tokidx   int
	peek     token.Token
	tok      token.Token
	prev     token.Token
	scope    &ast.Scope
	label    string
}

pub fn parse(main_file string, table &ast.Table) []&ast.File {
	mut parsed_files := []string{}
	defer {
		table.print_path_sep('start of parse')
	}
	return parse_file(main_file, table, [os.dir(main_file),
		os.join_path(os.dir(os.executable()), 'plib')], 'main', 'main', mut parsed_files)
}

fn parse_file(file string, table &ast.Table, search_paths []string, mod string, full_mod string, mut parsed_files []string) []&ast.File {
	mut p := Parser{
		table: table
		mod: mod
		full_mod: full_mod
		file: &ast.File{
			filename: file
			full_mod: full_mod
			imports: {
				mod:       full_mod
				'builtin': 'builtin'
			}
			scope: 0
		}
		toks: scanner.scan(file)
		scope: ast.new_scope(table.global_scope, 0, file)
	}
	p.file.scope = p.scope
	p.tokidx = 0
	p.next()
	p.next()
	p.parse_imports()
	mut files := []&ast.File{}
	if p.file.imports.len > 1 {
		for submod, full_submod in p.file.imports {
			if full_submod == full_mod { // skip self
				continue
			}

			mut path := ''
			mut filenames := []string{}
			mut success := false
			for sp in search_paths {
				path = os.join_path(sp, ...full_submod.split('.'))
				filenames = os.ls(path) or { continue }
				success = true
				break
			}
			if !success {
				p.error('module not found: ${full_submod}')
				continue
			}

			for filename in filenames {
				file_to_parse := os.join_path(path, filename)
				if file_to_parse in parsed_files {
					continue
				}
				parsed_files << file_to_parse
				if !filename.ends_with('.pr') || os.is_dir(filename) {
					continue
				}
				files << parse_file(file_to_parse, table, search_paths, submod, full_submod, mut
					parsed_files)
			}
		}
	}
	p.parse()
	files << p.file
	return files
}

fn (mut p Parser) parse() {
	mut decls := []string{}
	mut methods := []&ast.FnStmt{}
	for p.tok.kind != .eof {
		p.table.print_path_sep('start of parse loop')
		match p.tok.kind {
			.key_fn {
				fun := p.fun()
				if fun.is_method {
					methods << fun
				} else {
					decls << fun.name
					p.table.decls[p.full_mod][fun.name] = fun
				}
			}
			.key_struct, .key_enum {
				decl := p.type_decl()
				if decl is ast.Struct {
					decls << decl.name
					p.table.decls[p.full_mod][decl.name] = &decl
				} else if decl is ast.Enum {
					decls << decl.name
					p.table.decls[p.full_mod][decl.name] = &decl
				} else {
					panic('unknown type decl ${decl.type_name()}')
				}
			}
			.name {
				if p.peek.kind == .decl_assign {
					assign := p.stmt()
					name := ((assign as ast.AssignStmt).left as ast.Ident).name
					decls << name
					p.table.decls[p.full_mod][name] = &assign
					println('~${p.full_mod}:${name}~')
					p.table.print_path_sep('after parsing assign')
				} else {
					p.error('unexpected ${p.peek.kind} after name in declaration')
				}
			}
			else {
				p.error('unexpected ${p.tok.kind} in declaration')
			}
		}
	}
	p.file.decls = decls
	p.file.methods = methods
}

fn (mut p Parser) next() {
	p.prev = p.tok
	p.tok = p.peek
	p.peek = p.toks[p.tokidx]
	p.tokidx++
}

fn (mut p Parser) back(n int) {
	p.tokidx -= n
	p.prev = p.peek(-3)
	p.tok = p.peek(-2)
	p.peek = p.peek(-1)
}

// p.peek(0) == p.peek
fn (mut p Parser) peek(i int) token.Token {
	return p.toks[p.tokidx + i]
}

[noreturn]
fn (mut p Parser) error(err string) {
	util.error(p.file.filename, p.tok.Pos, 'parser', err)
	exit(1)
}

fn (mut p Parser) check(kind token.Kind) {
	if p.tok.kind != kind {
		p.error('unexpected ${p.tok.kind}, expecting ${kind}')
	}
	p.next()
}

fn (mut p Parser) open_scope() {
	scope := ast.new_scope(p.scope, p.tok.i, p.file.filename)
	p.scope = scope
}

fn (mut p Parser) close_scope() &ast.Scope {
	scope := p.scope
	p.scope.to = p.tok.i
	p.scope = p.scope.parent
	p.scope.children << scope
	return scope
}

fn (mut p Parser) parse_imports() {
	for p.tok.kind == .key_import {
		p.check(.key_import)
		mut name := p.tok.lit
		mut last := name
		p.check(.name)
		for p.tok.kind == .dot {
			p.next()
			name += '.${p.tok.lit}'
			last = p.tok.lit
			p.check(.name)
		}
		if last in p.file.imports {
			p.error('duplicate import: `${last}` already exists')
		}
		p.file.imports[last] = name
	}
}
