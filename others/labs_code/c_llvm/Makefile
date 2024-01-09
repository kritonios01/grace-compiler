.PHONY: clean distclean default

LLVMCONFIG=llvm-config-15

CXX=clang++
CXXFLAGS=-Wall -g `$(LLVMCONFIG) --cxxflags`
LDFLAGS=`$(LLVMCONFIG) --ldflags --system-libs --libs all`

default: mbc

lexer.cpp: lexer.l
	flex -s -o lexer.cpp lexer.l

lexer.o: lexer.cpp lexer.hpp parser.hpp ast.hpp

parser.hpp parser.cpp: parser.y
	bison -dv -o parser.cpp parser.y

parser.o: parser.cpp lexer.hpp ast.hpp

mbc: lexer.o parser.o ast.o
	$(CXX) $(CXXFLAGS) -o mbc $^ $(LDFLAGS)

clean:
	$(RM) lexer.cpp parser.cpp parser.hpp parser.output *.o *.s

distclean: clean
	$(RM) mbc a.out
