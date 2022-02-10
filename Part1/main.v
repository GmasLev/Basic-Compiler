

struct Lexer {
	mut:
	source			string
	currchar		byte
	currpos			int
	token			Token
}

struct Token {
	mut:
	text			string
	kind			map[string]int
	tokenkind		string
}
// Token Constructor
fn (mut self Token) inittoken(input string, tokentype string) &Token {
	// # The token's actual text. Used for identifiers, strings, and numbers.
	self.text = input   		
	// # The TokenType that this token is classified as.
	self.kind = {
		'eof': -1,
		'newline': 0,
		'number': 1,
		'ident': 2,
		'string': 3,
		//'__keywords__': -2,
		'label': 101,
		'goto': 102,
		'print': 103,
		'input': 104,
		'let': 105,
		'if': 106,
		'then': 107,
		'endif': 108,
		'while': 109,
		'repeat': 110,
		'endwhile': 111,
		//'__operators__': -2,
		'eq': 201,  
		'plus': 202,
		'minus': 203,
		'asterisk': 204,
		'slash': 205,
		'eqeq': 206,
		'noteq': 207,
		'lt': 208,
		'lteq': 209,
		'gt': 210,
		'gteq': 211
	}
	self.tokenkind = tokentype
	return &Token{self.text, &self.kind, self.tokenkind}
}
// 2o Token Constructor
fn (mut self Token) token(input string, tokentype string) &Token {
	self.text = input
	self.tokenkind = tokentype
	///*println(&self.kind)
	self.kind = {
		'eof': -1,
		'newline': 0,
		'number': 1,
		'ident': 2,
		'string': 3,
		//'__keywords__': -2,
		'label': 101,
		'goto': 102,
		'print': 103,
		'input': 104,
		'let': 105,
		'if': 106,
		'then': 107,
		'endif': 108,
		'while': 109,
		'repeat': 110,
		'endwhile': 111,
		//'__operators__': -2,
		'eq': 201,  
		'plus': 202,
		'minus': 203,
		'asterisk': 204,
		'slash': 205,
		'eqeq': 206,
		'noteq': 207,
		'lt': 208,
		'lteq': 209,
		'gt': 210,
		'gteq': 211
	}
	//println(&self.kind)*/
	return &Token{self.text, &self.kind, self.tokenkind}
}
// Lexer Constructor      	
fn (mut self Lexer) initlexer(input string) {
	self.source = input + (`\n`).str()  // Source code to lex as a string. 
										// Append a newline to simplify lexing/parsing the last token/statement.
	self.currchar = ` `   				// Current character in the string.
	self.currpos = -1    				// Current position in the string.
	self.nextchar()
	//self.token = self.gettoken()
}
// Process the next character.
fn (mut self Lexer) nextchar() {
	self.currpos++
	if self.currpos >= (self.source).len {
		self.currchar = `\0`  			// EOF
	} else {
		self.currchar = self.source[self.currpos]
	}
}
// Return the lookahead character.
fn (mut self Lexer) peek() byte {
	if self.currpos + 1 >= (self.source).len {
		return `\0`
	}
	return self.source[self.currpos+1]
}
// Invalid token found, print error message and exit.
fn (mut self Lexer) abort(message string) {
	eprintln("Lexing error. " + message)
	exit(1)
}
// Skip whitespace except newlines, which we will use to indicate the end of a statement.
fn (mut self Lexer) skipwhitespace() {
	for self.currchar == ` ` || self.currchar == `\t` || self.currchar == `\r` {
		self.nextchar()
	}
}	
// Skip comments in the code.
fn (mut self Lexer) skipcomment() {
	if self.currchar == `#` {
		for self.currchar != `\n` {
			self.nextchar()
		}
	}
}
// # Return the next token.
fn (mut self Lexer) gettoken() &Token {
	self.skipwhitespace()
	self.skipcomment()
	mut token := &Token{}
	token = self.token.token("","")
	//# Check the first character of this token to see if we can decide what it is.
	//# If it is a multiple character operator (e.g., !=), 
	//  number, identifier, or keyword then we will process the rest.
	if self.currchar == `+` {
		token = self.token.token((self.currchar).str(), 'plus')
	}
	else if self.currchar == `-` {
		token = self.token.token((self.currchar).str(), 'minus')
	}
	else if self.currchar == `*` {
		token = self.token.token((self.currchar).str(), 'asterisk')
	}
	else if self.currchar == `/` {
		token = self.token.token((self.currchar).str(), 'slash')
	}
	else if self.currchar == `=` {
		// # Check whether this token is = or ==
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'eqeq')
		}
		else {
			token = self.token.token((self.currchar).str(), 'eq')
		}
	}
	else if self.currchar == `>` {
		// # Check whether this is token is > or >=
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'gteq')
		}
		else {
			token = self.token.token((self.currchar).str(), 'gt')
		}
	}
	else if self.currchar == `<` {
			// # Check whether this is token is < or <=
			if self.peek() == `=` {
				lastchar := self.currchar
				self.nextchar()
				token = self.token.token((lastchar + self.currchar).str(), 'lteq')
			}
			else {
				token = self.token.token((self.currchar).str(), 'lt')
			}
	}
	else if self.currchar == `!` {
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'noteq')
		}
		else {
			self.abort("Expected !=, got !" + (self.peek()).str())
		}
	}
	else if self.currchar == `\"` {
		// # Get characters between quotations.
		self.nextchar()
		startpos := self.currpos

		for self.currchar != `\"` {
			// # Don`t allow special characters in the string. No escape characters, newlines, tabs, or %.
			// # We will be using C`s printf on this string.
			if self.currchar == `\r` || self.currchar == `\n` || self.currchar == `\t` || self.currchar == `\\` || self.currchar == `%` {
				self.abort("Illegal character in string.")
			}
			self.nextchar()
		}
		toktext := self.source[startpos..self.currpos] 					// # Get the substring.
		token = self.token.token(toktext, 'string')
	}
	else if isdigit(self.currchar) {
		// # Leading character is a digit, so this must be a number.
		// # Get all consecutive digits and decimal if there is one.
		startpos := self.currpos
		for self.peek().is_digit() {
			self.nextchar()
		}
		if self.peek() == `.` {				//: # Decimal!
			self.nextchar()
			// # Must have at least one digit after decimal.
			if !self.peek().is_digit() { 
				// # Error!
				self.abort("Illegal character in number.")
			}
			for self.peek().is_digit() {
				self.nextchar()
			}
		}
		toktext := self.source[startpos..self.currpos + 1] 			// # Get the substring.
		token = self.token.token(toktext, 'number')
	}
	else if self.currchar.is_letter() {
		// # Leading character is a letter, so this must be an identifier or a keyword.
		// # Get all consecutive alpha numeric characters.
		startpos := self.currpos
		for isalnum(self.peek()) {
			self.nextchar()
		}
		// # Check if the token is in the list of keywords.
		toktext := self.source[startpos..self.currpos + 1] 			// # Get the substring.
		keyword := checkifkeyword(toktext)
		if keyword == "NONE" {										// : # Identifier
			token = self.token.token(toktext, 'ident')
		}
		else {														// :   # Keyword
			token = self.token.token(toktext, keyword)
		}
	}
	else if self.currchar == `\n` {
		token = self.token.token((self.currchar).str(), 'newline')
	}
	else if self.currchar == `\0` {
		token = self.token.token(' ', 'eof')
	}
	else {
		// # Unknown token!
		self.abort("Unknown token: " + (self.currchar).str())
	}
	self.nextchar()
	return token
}

fn checkifkeyword(tokentext string) string {
	mut tok := Token{}
	tok = tok.token("","")
	//println('${tok.kind[tokentext.to_lower()]} => $tokentext.to_lower()')
	if tokentext.to_lower() in tok.kind { 		// TokenType // # Relies on all keyword enum values being 1XX.
		if tok.kind[tokentext.to_lower()] >= 100 && tok.kind[tokentext.to_lower()] < 200 {
			return tokentext.to_lower()
		}
	}
	return "NONE"
}

fn isdigit(c byte) bool {
	return c >= `0` && c <= `9`
}
fn isalnum(c byte) bool {
	return (c >= `A` && c <= `Z`) ||
		   (c >= `a` && c <= `z`) ||
		   (c >= `0` && c <= `9`) || (c == `_`)
}

fn main() {
	mut input := "LET foobar = 123"
	mut lexer := &Lexer{}
	mut token := &Token{}
	lexer.initlexer(input)
	for lexer.peek() != `\0` {
		print(lexer.currchar)
		lexer.nextchar()
	}
	println(' ')
	input = "+- */"
	lexer.initlexer(input)
	token = token.inittoken("","")
	token = lexer.gettoken()
	//println(token)
	//println(token.tokenkind)
	//println(token.kind[token.tokenkind])
	//println(token.kind['eof'])
	println(input)
	for token.kind[token.tokenkind] != token.kind['eof'] {
		match token.kind[token.tokenkind] {
			202 	{println("Plus")}
			203 	{println("Minus")}
			204 	{println("Asterisk")}
			205 	{println("SLASH")}
			else	{println("NewLine")}
		}
        //println(token.kind[token.tokenkind])
        token = lexer.gettoken()
	}
	println(' ')
	input = "IF+-123 foo*THEN/"
	println(input)
	lexer.initlexer(input)
	token = token.inittoken("","")
	token = lexer.gettoken()
	for token.kind[token.tokenkind] != token.kind['eof'] {
		println(token.tokenkind)
        token = lexer.gettoken()
	}
	println(' ')
	input = "+-123 9.8654*/"
	println(input)
	lexer.initlexer(input)
	token = token.inittoken("","")
	token = lexer.gettoken()
	for token.kind[token.tokenkind] != token.kind['eof'] {
		println(token.tokenkind)
        token = lexer.gettoken()
	}
	println(' ')
	input = "+- \"This is a string\" # This is a comment!\n */"
	println(input)
	lexer.initlexer(input)
	token = token.inittoken("","")
	token = lexer.gettoken()
	for token.kind[token.tokenkind] != token.kind['eof'] {
		println(token.tokenkind)
        token = lexer.gettoken()
	}
}