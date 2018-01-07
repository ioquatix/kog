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
	
	newline = "\n" | ';' | empty;
	
	unicode = any - ascii;
	identifier_character = [a-zA-Z0-9_];
	
	action mark_begin {
		std::cerr << "mark_begin: " << std::string(p, pe) << std::endl;
		mark = p;
	}
	
	action mark_end {
		std::cerr << "mark_end: " << std::string(mark, p) << std::endl;
	}
	
	action identifier_begin {
		identifier_mark = p;
	}
	
	action identifier_end {
		std::cerr << "identifier_end: " << std::string(identifier_mark, p) << std::endl;
	}
	
	identifier = identifier_character+ >identifier_begin %identifier_end;
	
	symbol = ":" identifier;
	quoted_string = '"' (any - '"')* '"';
	
	terminal = (symbol | quoted_string) >mark_begin %mark_end;
	
	action nested_expression {
		std::cerr << "nested_expression: " << std::string(p, pe) << std::endl;
		
		fcall nested_expression;
	}
	
	action nested_expression_exit {
		std::cerr << "nested_expression_exit" << std::endl;
		
		fret;
	}
	
	action nested_arguments {
		std::cerr << "parsing nested arguments: " << std::string(p, pe) << std::endl;
		arguments_mark = p;
		fcall nested_arguments;
	}
	
	action flat_arguments {
		std::cerr << "parsing flat arguments: " << std::string(p, pe) << std::endl;
		arguments_mark = p;
		fcall flat_arguments;
	}
	
	action arguments_exit {
		std::cerr << "arguments: " << std::string(arguments_mark, p) << std::endl;
		fret;
	}
	
	arguments = (
		('(' >nested_arguments) |
		(space >flat_arguments)
	);
	
	function_invoke = terminal | (identifier arguments);
	method_invoke = (('(' @nested_expression) | function_invoke) ("." identifier arguments)*;
	
	expression = space* (method_invoke);
	expressions = expression (space* "," expression)*;
	
	flat_arguments := expressions newline @arguments_exit;
	nested_arguments := expressions ")" @arguments_exit;
	nested_expression := expressions ")" @nested_expression_exit;
	
	action if_statement {std::cerr << "if_statement" << std::endl;}
	action unless_statement {std::cerr << "unless_statement" << std::endl;}
	action do_statement {std::cerr << "do_statement" << std::endl;}
	action module_statement {std::cerr << "module_statement" << std::endl;}
	action class_statement {std::cerr << "class_statement" << std::endl;}
	action assignment_statement {std::cerr << "assignment_statement" << std::endl;}
	action expression_statement {std::cerr << "expression_statement" << std::endl;}
	
	action parse_error {std::cerr << "parse error" << std::endl;}
	
	statement := (
		("if " expression newline) %if_statement |
		("unless " expression newline) %unless_statement |
		(expression " do") %do_statement |
		("module " identifier newline) %module_statement |
		("class " identifier newline) %class_statement |
		(expressions " = " expressions newline) %assignment_statement |
		(expression) %expression_statement
	)+;
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
		
		auto p = reinterpret_cast<const unsigned char *>(buffer.data());
		auto pe = p + buffer.size();
		auto eof = pe;
		
		decltype(p) mark, arguments_mark, identifier_mark;
		
		%% write init;
		%% write exec;
		
		if (top > 0) {
			cs = %%{ write error; }%%;
		}
		
		if (p < pe) {
			std::cerr << "failed to parse all input, stopped at " << std::string(p, pe) << std::endl;
		}
	}
}
