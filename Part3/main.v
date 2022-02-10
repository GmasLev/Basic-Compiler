



enum TokenType {
	eof
	newline
	number
	ident
	string_
	__keywords__
	label
	goto_
	print
	input
	let
	if_
	then
	endif
	while
	repeat
	endwhile
	__operators__
	eq
	plus
	minus
	asterisk
	slash
	eqeq
	noteq
	lt
	lteq
	gt
	gteq
}
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
	tokenkind		string
	tokentype		TokenType
	kind			map[string]int
	kindtoken		map[string]int
}
struct Parser {
	mut:
	lexer				Lexer
	symbols				[]string
	labelsdeclared		[]string
	labelsgotoed		[]string
	curtoken			Token
	peektoken			Token
}
//#######################################################################
//########################LEXER##########################################
//#######################################################################
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
	token = self.token.token("","",TokenType.eof)
	//# Check the first character of this token to see if we can decide what it is.
	//# If it is a multiple character operator (e.g., !=), 
	//  number, identifier, or keyword then we will process the rest.
	if self.currchar == `+` {
		token = self.token.token((self.currchar).str(), 'plus', TokenType.plus)
	}
	else if self.currchar == `-` {
		token = self.token.token((self.currchar).str(), 'minus', TokenType.minus)
	}
	else if self.currchar == `*` {
		token = self.token.token((self.currchar).str(), 'asterisk', TokenType.asterisk)
	}
	else if self.currchar == `/` {
		token = self.token.token((self.currchar).str(), 'slash', TokenType.slash)
	}
	else if self.currchar == `=` {
		// # Check whether this token is = or ==
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'eqeq', TokenType.eqeq)
		}
		else {
			token = self.token.token((self.currchar).str(), 'eq', TokenType.eq)
		}
	}
	else if self.currchar == `>` {
		// # Check whether this is token is > or >=
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'gteq', TokenType.gteq)
		}
		else {
			token = self.token.token((self.currchar).str(), 'gt', TokenType.gt)
		}
	}
	else if self.currchar == `<` {
			// # Check whether this is token is < or <=
			if self.peek() == `=` {
				lastchar := self.currchar
				self.nextchar()
				token = self.token.token((lastchar + self.currchar).str(), 'lteq', TokenType.lteq)
			}
			else {
				token = self.token.token((self.currchar).str(), 'lt',TokenType.lt)
			}
	}
	else if self.currchar == `!` {
		if self.peek() == `=` {
			lastchar := self.currchar
			self.nextchar()
			token = self.token.token((lastchar + self.currchar).str(), 'noteq', TokenType.noteq)
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
			if 	self.currchar == `\r` || self.currchar == `\n` || 
				self.currchar == `\t` || self.currchar == `\\` || 
				self.currchar == `%` {
				self.abort("Illegal character in string.")
			}
			self.nextchar()
		}
		toktext := self.source[startpos..self.currpos] 					// # Get the substring.
		token = self.token.token(toktext, 'string', TokenType.string_)
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
		token = self.token.token(toktext, 'number', TokenType.number)
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
			token = self.token.token(toktext, 'ident', TokenType.ident)
		}
		else {														// :   # Keyword
			tt := match keyword {
				'label'		{TokenType.label}
				'goto'		{TokenType.goto_}
				'print'		{TokenType.print}
				'input'		{TokenType.input}
				'let'		{TokenType.let}
				'if' 		{TokenType.if_}
				'then'		{TokenType.then}
				'endif'		{TokenType.endif}
				'while'		{TokenType.while}
				'repeat'	{TokenType.repeat}
				else		{TokenType.endwhile}
			}
			token = self.token.token(toktext, keyword, tt)
		}
	}
	else if self.currchar == `\n` {
		token = self.token.token((self.currchar).str(), 'newline', TokenType.newline)
	}
	else if self.currchar == `\0` {
		token = self.token.token(' ', 'eof', TokenType.eof)
	}
	else {
		// # Unknown token!
		self.abort("Unknown token: " + (self.currchar).str())
	}
	self.nextchar()
	return token
}
fn isdigit(c byte) bool {
	return c >= `0` && c <= `9`
}
fn isalnum(c byte) bool {
	return (c >= `A` && c <= `Z`) ||
		   (c >= `a` && c <= `z`) ||
		   (c >= `0` && c <= `9`) || (c == `_`)
}
//#######################################################################
//########################TOKEN##########################################
//#######################################################################
// Token Constructor
fn (mut self Token) inittoken(input string, tokentype string) &Token {
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
	self.text = input
	self.tokenkind = tokentype
	self.kindtoken[tokentype] = self.kind[tokentype]
	self.tokentype = TokenType.eof
	return &Token{self.text, self.tokenkind, self.tokentype, &self.kind, &self.kindtoken}
}
// 2o Token Constructor
fn (mut self Token) token(input string, tokentype string, tt TokenType) &Token {
	self.text = input
	self.tokenkind = tokentype
	self.tokentype = tt
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
	self.kindtoken[tokentype] = self.kind[tokentype]
	return &Token{self.text, self.tokenkind, self.tokentype, &self.kind, &self.kindtoken}
}
fn checkifkeyword(tokentext string) string {
	mut tok := Token{}
	tok = tok.token("","",TokenType.eof)
	//println('${tok.kind[tokentext.to_lower()]} => $tokentext.to_lower()')
	// TokenType // # Relies on all keyword enum values being 1XX.
	if tokentext.to_lower() in tok.kind { 		
		if tok.kind[tokentext.to_lower()] >= 100 && 
		tok.kind[tokentext.to_lower()] < 200 {
			return tokentext.to_lower()
		}
	}
	return "NONE"
}
//#######################################################################
//#########################PARSER########################################
//#######################################################################
// # Advances the current token.
fn (mut self Parser) nexttoken() {
	self.curtoken = self.peektoken
	self.peektoken = self.lexer.gettoken()
	// # No need to worry about passing the EOF, lexer handles that.
}
// Parser Constructor
fn (mut self Parser) initparser(lexer Lexer) {
	self.lexer = lexer

	self.symbols = []string{}    		//# All variables we have declared so far.
	self.labelsdeclared = []string{} 	//# Keep track of all labels declared
	self.labelsgotoed = []string{} 		//# All labels goto'ed, so we know if they exist or not.

	self.curtoken = Token{}
	self.peektoken = Token{}
	self.nexttoken()
	self.nexttoken()    			//# Call this twice to initialize current and peek.
}
//# Return true if the current token matches.
fn (mut self Parser) checktoken(kind TokenType) bool {
	return kind == self.curtoken.tokentype
}
//# Return true if the next token matches.
fn (mut self Parser) checkpeek(kind TokenType) bool {
	return kind == self.peektoken.tokentype
}
//# Try to match current token. If not, error. Advances the current token.
fn (mut self Parser) match_(kind TokenType)  {
	if !self.checktoken(kind) {
		self.abort_("Expected ${kind} got 
					${self.curtoken.tokentype}")
	}
	self.nexttoken()
}
//# Return true if the current token is a comparison operator.
fn (mut self Parser) iscomparisonoperator() bool {
	if	self.checktoken(TokenType.gt) || 
		self.checktoken(TokenType.gteq) || 
		self.checktoken(TokenType.lt) ||
		self.checktoken(TokenType.lteq) || 
		self.checktoken(TokenType.eqeq) || 
		self.checktoken(TokenType.noteq) {
			return true
		}
		return false
}
fn (mut self Parser) abort_(message string) {
	eprintln("Error Parser. " + message)
	exit(1)
}
//# Production rules.      #################################
//# program ::= {statement}  ###############################
//##########################################################
fn (mut self Parser) program() {
	println("PROGRAM")
	//# Since some newlines are required in our grammar, need to skip the excess.
	for self.checktoken(TokenType.newline) {
		self.nexttoken()
	}
	//# Parse all the statements in the program.
	for !(self.checktoken(TokenType.eof)) {
		self.statement()
	}
	//# Check that each label referenced in a GOTO is declared.
	for label in self.labelsgotoed {
		if label in self.labelsdeclared {			// !(... in ...)##############################
			self.abort_("Attempting to GOTO to undeclared label: $label")
		}
	}
}
//# One of the following statements...
fn (mut self Parser) statement() {
	//# Check the first token to see what kind of statement this is.
	//# "PRINT" (expression | string)
	if self.checktoken(TokenType.print) {
		println("STATEMENT-PRINT")
		self.nexttoken()
	
		if self.checktoken(TokenType.string_) {
			//# Simple string.
			self.nexttoken()
		}
		else {
			//# Expect an expression.
			self.expression()
		}
	}
	//# "IF" comparison "THEN" {statement} "ENDIF"
	else if self.checktoken(TokenType.if_) {
		println("STATEMENT-IF")
		self.nexttoken()
		self.comparison()

		self.match_(TokenType.then)
		self.nl()

		//# Zero or more statements in the body.
		for !(self.checktoken(TokenType.endif)) {
			self.statement()
		}
		self.match_(TokenType.endif)
	}
	//# "WHILE" comparison "REPEAT" {statement} "ENDWHILE"
	else if self.checktoken(TokenType.while) {
		println("STATEMENT-WHILE")
		self.nexttoken()
		self.comparison()

		self.match_(TokenType.repeat)
		self.nl()

		//# Zero or more statements in the loop body.
		for !(self.checktoken(TokenType.endwhile)) {
			self.statement()
		}
		self.match_(TokenType.endwhile)
	}
	//# "LABEL" ident
	else if self.checktoken(TokenType.label) {
		println("STATEMENT-LABEL")
		self.nexttoken()

		//# Make sure this label doesn't already exist.
		if self.curtoken.text in self.labelsdeclared {				// !(... in ...)##############################
			self.abort_("Label already exists: $self.curtoken.text")
		}
		self.labelsdeclared<<(self.curtoken.text)

		self.match_(TokenType.ident)
	}
	//# "GOTO" ident
	else if self.checktoken(TokenType.goto_) {
		println("STATEMENT-GOTO")
		self.nexttoken()
		self.labelsgotoed<<(self.curtoken.text)
		self.match_(TokenType.ident)
	}
	//# "LET" ident "=" expression
	else if self.checktoken(TokenType.let) {
		println("STATEMENT-LET")
		self.nexttoken()

		//#  Check if ident exists in symbol table. If not, declare it.
		if self.curtoken.text in self.symbols {			// !(... in ...) #################################
			self.symbols<<(self.curtoken.text)
		}
		self.match_(TokenType.ident)
		self.match_(TokenType.eq)
		
		self.expression()
	}
	//# "INPUT" ident
	else if self.checktoken(TokenType.input) {
		println("STATEMENT-INPUT")
		self.nexttoken()

		//# If variable doesn't already exist, declare it.
		if self.curtoken.text in self.symbols {			// !(... in ...) ##########################
			self.symbols<<(self.curtoken.text)
		}
		self.match_(TokenType.ident)
	}
	//# This is not a valid statement. Error!
	else {
		self.abort_("Invalid statement at $self.curtoken.text ($self.curtoken.tokentype)")
	}
	//# Newline.
	self.nl()
}
//# comparison ::= expression (("==" | "!=" | ">" | ">=" | "<" | "<=") expression)+
fn (mut self Parser) comparison() {
	println("COMPARISON")

	self.expression()
	//# Must be at least one comparison operator and another expression.
	if self.iscomparisonoperator() {
		self.nexttoken()
		self.expression()
	}
	else {
		self.abort_("Expected comparison operator at: $self.curtoken.text")
	}
	//# Can have 0 or more comparison operator and expressions.
	for self.iscomparisonoperator() {
		self.nexttoken()
		self.expression()
	}
}
//# expression ::= term {( "-" | "+" ) term}
fn (mut self Parser) expression() {
	println("EXPRESSION")

	self.term()
	//# Can have 0 or more +/- and expressions.
	for self.checktoken(TokenType.plus) || self.checktoken(TokenType.minus) {
		self.nexttoken()
		self.term()
	}
}
//# term ::= unary {( "/" | "*" ) unary}
fn (mut self Parser) term() {
	println("TERM")
	self.unary()
	//# Can have 0 or more *// and expressions.
	for self.checktoken(TokenType.asterisk) || self.checktoken(TokenType.slash) {
		self.nexttoken()
		self.unary()
	}
}
//# unary ::= ["+" | "-"] primary
fn (mut self Parser) unary() {
	println("UNARY")
	//# Optional unary +/-
	if self.checktoken(TokenType.plus) || self.checktoken(TokenType.minus) {
		self.nexttoken()
	}
	self.primary()
}
//# primary ::= number | ident
fn (mut self Parser) primary() {
	println("PRIMARY ($self.curtoken.text)")

	if self.checktoken(TokenType.number) { 
		self.nexttoken()
	}
	else if self.checktoken(TokenType.ident) {
		//# Ensure the variable already exists.
		if self.curtoken.text in self.symbols {				// !(... in ...) #################################
			self.abort_("Referencing variable before assignment: $self.curtoken.text")
		}
		self.nexttoken()
	}
	else {
		//# Error!
		self.abort_("Unexpected token at $self.curtoken.text")
	}
}
//# nl ::= '\n'+
fn (mut self Parser) nl() {
	println("NEWLINE")

	//# Require at least one newline.
	self.match_(TokenType.newline)
	//# But we will allow extra newlines too, of course.
	for self.checktoken(TokenType.newline) {
		self.nexttoken()
	}
}
//#######################################################################
//########################### MAIN() ####################################
//#######################################################################
fn main() {
	mut input := 	"
					PRINT \"How many fibonacci numbers do you want?\"
					INPUT nums
					PRINT \"\"

					LET a = 0
					LET b = 1
					WHILE nums > 0 REPEAT
						PRINT a
						LET c = a + b
						LET a = b
						LET b = c
						LET nums = nums - 1
					ENDWHILE
					"
	mut lexer := &Lexer{}
	mut parser := &Parser{}

	lexer.initlexer(input)
	parser.initparser(lexer)

    parser.program() //# Start the parser.
    println("Parsing completed.")
}
