import os

fn main() {
	mut contents := os.open_file('hola.txt','w+') or { panic(err) }
	
	println(contents)
}