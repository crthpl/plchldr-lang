module checker

import ast

fn (mut c Checker) plchldr(info ast.Placeholder) ast.Type {
	return c.table.names[info]
}
