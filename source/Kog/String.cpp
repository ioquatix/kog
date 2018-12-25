//
//  String.cpp
//  This file is part of the "Kog" project and released under the MIT License.
//
//  Created by Samuel Williams on 24/12/2018.
//  Copyright, 2018, by Samuel Williams. All rights reserved.
//

#include "String.hpp"

#include <iostream>

namespace Kog
{
	String::String()
	{
	}
	
	String::~String()
	{
	}
	
	char convert_to_character(unsigned char d) {
		if (d < 10) {
			return '0' + d;
		} else if (d < 36) {
			return 'A' + (d - 10);
		}
		
		throw std::range_error("Could not convert digit to character - out of range!"); 
	}
	
	unsigned char convert_to_digit(char c) {
		auto d = c - '0';
		
		if (d < 10) {
			return d;
		} else {
			d = c - 'A';
			
			if (d < 26) {
				return d + 10;
			}
		}
		
		throw std::range_error("Could not convert character to digit - out of range!");
	}
	
	std::ostream & unescape_string(std::ostream & buffer, const std::string & value) {
		auto i = value.begin(), end = value.end();
		
		// Skip enclosing quotes
		++i;
		--end;
		
		for (; i < end; ++i) {
			if (*i == '\\') {
				++i;
				
				switch (*i) {
					case 'd':
						buffer << 4;
					case 't':
						buffer << '\t';
						continue;
					case 'r':
						buffer << '\r';
						continue;
					case 'n':
						buffer << '\n';
						continue;
					case '\\':
						buffer << '\\';
						continue;
					case '"':
						buffer << '"';
						continue;
					case '\'':
						buffer << '\'';
						continue;
					case 'x':
						if ((end - i) >= 2) {
							auto value = convert_to_digit(*(++i)) << 4;
							value |= convert_to_digit(*(++i));
							buffer << value;
							continue;
						} else {
							break;
						}
					case '.':
						continue;
				}
				
				throw std::runtime_error("Could not parse string escape!");
			} else {
				buffer << *i;
			}
		}
	
		return buffer;
	}
	
	std::ostream & escape_string(std::ostream & buffer, const std::string & value) {
		auto i = value.begin(), end = value.end();
		
		buffer << '"';
		
		for (; i != end; ++i) {
			switch (*i) {
				case 4:
					buffer << "\\d";
					continue;
				case '\n':
					buffer << "\\n";
					continue;
				case '\t':
					buffer << "\\t";
					continue;
				case '"':
					buffer << "\\\"";
					continue;
				default:
					buffer << *i;
			}
		}
		
		buffer << '"';
		
		return buffer;
	}
}
