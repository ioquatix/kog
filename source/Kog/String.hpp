//
//  String.hpp
//  This file is part of the "Kog" project and released under the MIT License.
//
//  Created by Samuel Williams on 24/12/2018.
//  Copyright, 2018, by Samuel Williams. All rights reserved.
//

#pragma once

#include <iosfwd>

namespace Kog
{
	class String
	{
	public:
		String();
		virtual ~String();
		
	private:
		
	};
	
	std::ostream & unescape_string(std::ostream & buffer, const std::string & value);
	std::ostream & escape_string(std::ostream & buffer, const std::string & value);
}
