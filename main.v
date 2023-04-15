module main

import os
import ast
import parser
import checker
import eval

fn main() {
	mut files := []string{}
	match os.args.len {
		1 {
			eprintln('todo: repl')
			exit(1)
		}
		else {
			files << os.args[1]
		}
	}
	mut asts := []&ast.File{}
	mut table := ast.new_table()
	for file in files {
		ast := parser.parse(file, table)
		asts << ast
	}
	table.print_path_sep('between parsing and checking')
	mut has_error := false
	for mut ast in asts {
		has_error = has_error || checker.check(mut *ast, table)
	}
	if has_error {
		exit(1)
	}
	eval.eval(asts, table)
}
