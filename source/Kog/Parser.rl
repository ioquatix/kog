//
//  Parser.cpp
//  This file is part of the "Kog" project and released under the MIT License.
//
//  Created by Samuel Williams on 7/1/2018.
//  Copyright, 2018, by Samuel Williams. All rights reserved.
//

#include <Kog/String.hpp>
#include <Kog/Parser.hpp>

#include <iostream>

%%{
	machine kog;
	alphtype unsigned char;
	
	# End Of Transmission (Ctrl-D from terminal)
	eot = 4;
	
	newline = "\n" | eot;
	eos = space* (newline | ";");
	
	unicode = any - ascii;
	identifier_character = [a-zA-Z_];
	
	action terminal_begin {
		terminal_mark = p;
	}
	
	action terminal_end {
		log(level, "terminal", terminal_mark, p);
	}
	
	action identifier_begin {
		identifier_mark = p;
	}
	
	action identifier_end {
	}
	
	identifier = identifier_character+ >identifier_begin %identifier_end;
	
	symbol = ":" identifier;
	quoted_string = '"' (any - '"')* '"';
	decimal = [+\-]? digit+ ("." digit+ ("e" digit+)?)?;
	heximal = "0x" xdigit+;
	
	terminal = (symbol | quoted_string | decimal | heximal) >terminal_begin %terminal_end;
	
	action nested_expression {
		std::cerr << "nested_expression: " << std::string(p, pe) << std::endl;
		
		fcall nested_expression;
	}
	
	action nested_expression_exit {
		std::cerr << "nested_expression_exit" << std::endl;
		
		fret;
	}
	
	action nested_array {
		//log(level, "parsing nested array", p, pe);
		
		arguments_mark = p;
		fcall nested_array;
	}
	
	action nested_index {
		//log(level, "parsing nested index", p, pe);
		
		arguments_mark = p;
		fcall nested_index;
	}
	
	action index_exit {
		fret;
	}
	
	action nested_arguments {
		//log(level, "parsing nested arguments", p, pe);
		
		arguments_mark = p;
		fcall nested_arguments;
	}
	
	action flat_arguments {
		log(level, "parsing flat arguments", p, pe);
		
		arguments_mark = p;
		fcall flat_arguments;
	}
	
	action arguments_exit {
		//log(level, "arguments", arguments_mark, p);
		
		fret;
	}
	
	action arguments_begin {
		level += 1;
		//log(level, "parsing arguments", p, pe);
	}
	
	action arguments_end {
		//log(level, "arguments", arguments_mark, p);
		level -= 1;
	}
	
	arguments = (
		('[' >nested_index)
		| ('(' >nested_arguments)
		| (space+ %flat_arguments)
	) >arguments_begin %arguments_end;
	
	action function_invoke_begin {
		//log(level, "parsing function invoke", p, pe);
		function_mark = p;
	}
	
	action function_invoke_end {
		log(level, "call function", function_mark, p);
	}
	
	function_invoke = terminal | (
		identifier arguments?
	) >function_invoke_begin %function_invoke_end;
	
	action method_begin {
		method_mark = p;
	}
	
	action method_end {
		log(level, "invoke method", method_mark, p);
	}
	
	method = ("." identifier arguments?) >method_begin %method_end;
	method_invoke = (('(' @nested_expression) | function_invoke) method*;
	
	action expression_begin {
		//log(level, "parsing expression", p, pe);
		
		expression_mark = p;
	}
	
	action expression_end {
		//log(level, "expression", expression_mark, p);
	}
	
	expression = method_invoke >expression_begin %expression_end;
	expressions = space* expression (space* "," space* expression space*)* ","?;
	
	keyed_expression = (expression | identifier) ":" expression;
	keyed_expressions = keyed_expression ("," keyed_expression)*;
	
	flat_arguments := expressions @arguments_exit;
	nested_index := expressions? "]" @index_exit;
	# nested_array := expressions? "]" @array_exit;
	# nested_table := keyed_expressions? "}" @table_exit;
	nested_arguments := expressions? ")" @arguments_exit;
	nested_expression := expressions? ")" @nested_expression_exit;
	
	action if_statement {log(level, "if", statement_mark, p);}
	action unless_statement {log(level, "unless", statement_mark, p);}
	action do_statement {log(level, "do", statement_mark, p);}
	action module_statement {log(level, "module", statement_mark, p);}
	action class_statement {log(level, "class", statement_mark, p);}
	action rescue_statement {log(level, "rescue", statement_mark, p);}
	action assignment_statement {log(level, "assignment", statement_mark, p);}
	action expression_statement {log(level, "expression", statement_mark, p);}
	
	action parse_error {std::cerr << "parse error" << std::endl;}
	
	action statement_begin {
		statement_mark = p;
		//log(level, "parsing statement", p, pe);
		
		level += 1;
	}
	
	action statement_end {
		//log(level, "statement", statement_mark, p);
		level -= 1;
	}
	
	end = space* "end" eos >{log(level, "end", p, pe);};
	
	if_statement = ("if" | "unless" . space) @{std::cerr << "if_statement" << std::endl; fcall if_body;};
	class_statement = ("module" | "class") space %class_statement >{fcall class_body;};
	
	comment = space* "#" (any - newline)* newline;
	whitespace = space+;
	
	statement = (
#		| if_statement
#		| class_statement
#		| (expression " rescue " expression) %rescue_statement
#		| (expressions " = " expressions) %assignment_statement
		expression %expression_statement
	) >statement_begin %statement_end eos;
	
	if_else = "else" statement;
	if_body := expression eos statement eos (end | if_else) @{fret;};
	
	class_body := statement* end @{fret;};
	
	statements = (whitespace | comment | statement)*;
	
	main := statements eot?;
}%%

%% write data;

namespace Kog
{
	Parser::Parser()
	{
	}
	
	Parser::~Parser()
	{
	}
	
	void Parser::parse(const std::string & buffer)
	{
		int stack[32], cs, top;
		std::size_t level = 0;
		
		auto p = reinterpret_cast<const unsigned char *>(buffer.data());
		auto pe = p + buffer.size();
		auto eof = pe;
		
		log(level, "parsing", p, pe);
		
		decltype(p) terminal_mark, arguments_mark, identifier_mark, statement_mark, expression_mark, function_mark, method_mark;
		
		%% write init;
		%% write exec;
		
		if (top > 0) {
			cs = %%{ write error; }%%;
		}
		
		if (cs < %%{write first_final;}%%) {
			std::cerr << "failed to finish parse in accepting state, stopped in state " << cs << std::endl;
		}
		
		if (p < pe) {
			std::cerr << "failed to parse all input, stopped at: ";
			
			std::string buffer(p, pe);
			escape_string(std::cerr, buffer);
			
			std::cerr << std::endl;
		}
	}
	
	void Parser::log(std::size_t level, const char * message, const unsigned char * begin, const unsigned char * end)
	{
		std::cerr << std::string(level, '\t') << message << ": ";
		
		std::string buffer(begin, end);
		escape_string(std::cerr, buffer);
		
		std::cerr << std::endl;
	}
}
