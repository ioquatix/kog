//
//  Parser.cpp
//  This file is part of the "Kog" project and released under the MIT License.
//
//  Created by Samuel Williams on 7/1/2018.
//  Copyright, 2018, by Samuel Williams. All rights reserved.
//

#include <Kog/Parser.hpp>
#include <iostream>

%%{
	machine kog;
	alphtype unsigned char;
	
	eot = 4;
	
	newline = "\n";
	eos = space* (newline | ";" | eot);
	
	unicode = any - ascii;
	identifier_character = [a-zA-Z0-9_];
	
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
	
	terminal = (symbol | quoted_string) >terminal_begin %terminal_end;
	
	action nested_expression {
		std::cerr << "nested_expression: " << std::string(p, pe) << std::endl;
		
		fcall nested_expression;
	}
	
	action nested_expression_exit {
		std::cerr << "nested_expression_exit" << std::endl;
		
		fret;
	}
	
	action nested_arguments {
		//log(level, "parsing nested arguments", p, pe);
		
		arguments_mark = p;
		fcall nested_arguments;
	}
	
	action flat_arguments {
		//log(level, "parsing flat arguments", p, pe);
		
		arguments_mark = p;
		fcall flat_arguments;
	}
	
	action arguments_exit {
		log(level, "arguments", arguments_mark, p);
		
		fret;
	}
	
	arguments = (
		('(' >nested_arguments)
		| ((space - eos)+ %flat_arguments)
	)?;
	
	action function_invoke_begin {
		//log(level, "parsing function invoke", p, pe);
		function_mark = p;
	}
	
	action function_invoke_end {
		log(level, "function invoke", function_mark, p);
	}
	
	function_invoke = (
		terminal |
		(identifier arguments)
	) >function_invoke_begin %function_invoke_end;
	
	action method_begin {
		method_mark = p;
	}
	
	action method_end {
		log(level, "method", method_mark, p);
	}
	
	method = ("." identifier arguments) >method_begin %method_end;
	method_invoke = (('(' @nested_expression) | function_invoke) method*;
	
	expression = method_invoke;
	expressions = expression (space* "," expression)*;
	
	flat_arguments := expressions @arguments_exit;
	nested_arguments := expressions? ")" @arguments_exit;
	nested_expression := expressions? ")" @nested_expression_exit;
	
	action comment_statement {log(level, "comment", statement_mark, p);}
	action if_statement {}
	action unless_statement {std::cerr << "[unless]" << std::endl;}
	action do_statement {std::cerr << "[do]" << std::endl;}
	action module_statement {std::cerr << "[module]" << std::endl;}
	action class_statement {std::cerr << "[class]" << std::endl;}
	action rescue_statement {std::cerr << "[rescue]" << std::endl;}
	action assignment_statement {std::cerr << "[assignment]" << std::endl;}
	action expression_statement {std::cerr << "[expression]" << std::endl;}
	
	action parse_error {std::cerr << "parse error" << std::endl;}
	
	action statement_begin {
		statement_mark = p;
		//log(level, "parsing statement", p, pe);
		
		level += 1;
	}
	
	action statement_end {
		log(level, "statement", statement_mark, p);
		level -= 1;
	}
	
	end = space* "end" eos >{log(level, "end", p, pe);};
	
	if_statement = ("if" | "unless" . space) @{std::cerr << "if_statement" << std::endl; fcall if_body;};
	class_statement = ("module" | "class") space %class_statement >{fcall class_body;};
	
	expression_statement = expression eos;
	comment_statement = space* "#" (any - newline)* newline;
	
	statement = space* (
#		| if_statement
#		| class_statement
#		| (expression " rescue " expression) %rescue_statement
#		| (expressions " = " expressions) %assignment_statement
		expression_statement %expression_statement
		| comment_statement %comment_statement
	) >statement_begin %statement_end;
	
	if_else = "else" statement;
	if_body := expression eos statement eos (end | if_else) @{fret;};
	
	class_body := statement* end @{fret;};
	
	main := statement*;
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
		
		decltype(p) terminal_mark, arguments_mark, identifier_mark, statement_mark, function_mark, method_mark;
		
		%% write init;
		%% write exec;
		
		if (top > 0) {
			cs = %%{ write error; }%%;
		}
		
		if (cs < %%{write first_final;}%%) {
			std::cerr << "failed to finish parse in accepting state, stopped in state " << cs << std::endl;
		}
		
		if (p < pe) {
			std::cerr << "failed to parse all input, stopped at " << std::string(p, pe) << std::endl;
		}
	}
	
	void Parser::log(std::size_t level, const char * message, const unsigned char * begin, const unsigned char * end)
	{
		std::cerr << std::string("\t", level) << message << ": '" << std::string(begin, end) << "'" << std::endl;
	}
}
