//
//  Parser.hpp
//  This file is part of the "Kog" project and released under the MIT License.
//
//  Created by Samuel Williams on 7/1/2018.
//  Copyright, 2018, by Samuel Williams. All rights reserved.
//

#pragma once

#include <string>

namespace Kog
{
	class Parser
	{
	public:
		struct Node {
			const char * begin;
			const char * end;
		};
		
		Parser();
		virtual ~Parser();
		
		void parse(const std::string & buffer);
		
	private:
		void log(std::size_t level, const char * message, const unsigned char * begin, const unsigned char * end);
	};
}
