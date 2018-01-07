
#include <Kog/Parser.hpp>

int main (int argc, char ** argv) {
	Kog::Parser parser;
	
	//parser.parse("(:foo, :bar)");
	parser.parse("puts \"Hello World\"\n");
	
	return 0;
}
