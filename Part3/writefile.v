import os

fn main() {
    /*fbytes := os.read_bytes('grammar.txt') or {
		error('Error: $err')
		return 
	}
	println(fbytes)*/

	mut contents := os.read_file('gramaticainterprete.txt') or { panic(err) }
	mut lines := contents.split('\t')
	println(lines)

	os.write_file('hola.txt', 'esto es una chingada prueba')
	contents = os.read_file('hola.txt') or { panic(err) }
	lines = contents.split(' ')
	println(lines)

}