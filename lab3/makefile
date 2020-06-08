CXX = clang++
CXXFLAGS = -g -Wall -std=c++11 -Wno-deprecated-register -Wno-unused-private-field -O0
LEX = flex
LFLAGS = --noline
YACC = bison --report=all -d -l -o olmeca_lang.cpp

EXE = olmeca
# Things that get included in our Yacc file
INCLUDED_FILES = \
	ast.hpp \
	subexpression.hpp \
	symtable.hpp \
        olmeca_driver.hpp

# The various .o files that are needed for executables.
OBJECT_FILES = olmeca_lang.o ast.o olmeca_lexer.o olmeca_driver.o symtable.o

default: olmeca

olmeca: $(OBJECT_FILES)
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

olmeca_lang.o: olmeca_lang.cpp olmeca_lexer.cpp $(INCLUDED_FILES)

olmeca_lang.cpp: olmeca.y
	$(YACC) $(YFLAGS) $^ -o olmeca_lang.cpp

olmeca_lexer.cpp: tokens.l
	$(LEX) $(LFLAGS) --outfile=olmeca_lexer.cpp $^

clean-all:
	make clean
	$(RM) olmeca

clean:
	-$(RM) *.o
	-$(RM) *.hh
	-$(RM) olmeca_lang.*
	-$(RM) olmeca_lexer.*
