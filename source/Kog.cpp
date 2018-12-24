
#include <Kog/Parser.hpp>

#include <iostream>
#include <streambuf>

int main (int argc, char ** argv) {
	Kog::Parser parser;
	
	std::string input{
		std::istreambuf_iterator<char>(std::cin),
		std::istreambuf_iterator<char>()
	};
	
	// Append EOT:
	input.append(1, 0x04);
	
	parser.parse(input);
	
	return 0;
}
