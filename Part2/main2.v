import os

fn main() {
    println("Teeny Tiny Compiler")
	mut lexer := &Lexer{}
	mut parser := &Parser{}
    if (os.args).len != 2 {
		eprintln("Error: Compiler needs source file as argument.")
        exit(1)
	}
    inputfile := vfopen(os.args[1], 'r') or {
		eprintln("Error: Compiler not open file.")
        exit(1)
	}
    input := inputfile.read()

    //# Initialize the lexer and parser.
    lexer = Lexer(input)
    parser = Parser(lexer)
	//# Start the parser.
    parser.program() 
    println("Parsing completed.")
}
