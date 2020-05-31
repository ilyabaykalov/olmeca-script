CXX = clang++
CXXFLAGS = -g -Wall -std=c++11 -Wno-deprecated-register -Wno-unused-private-field -O0
LEX = flex
LFLAGS = --noline
YACC = bison --report=all -d -l

EXE = olmeca

INCLUDED_FILES = \
	ast.hpp \
	subexpression.hpp \
	symtable.hpp \
        olmeca_driver.hpp


OBJECT_FILES = olmeca_lang.o ast.o olmeca_lexer.o olmeca_driver.o symtable.o

.PHONY: default
default: olmeca

.PHONY: olmeca
olmeca: $(OBJECT_FILES) olmeca.o
	$(CXX) $(CXXFLAGS) -o $@ $^ $(LIBS)

olmeca_lang.o: olmeca_lang.cpp $(INCLUDED_FILES)

.PHONY: olmeca_lang.cpp
olmeca_lang.cpp: olmeca.y
	$(YACC) $(YFLAGS) $^ -o olmeca_lang.cpp

olmeca_lexer.cpp: tokens.l
	$(LEX) $(LFLAGS) --outfile=olmeca_lexer.cpp $^

.PHONY: clean-all
clean-all:
	make clean
	$(RM) olmeca

.PHONY: clean
clean:
	-$(RM) *.o
	-$(RM) *.hh
	-$(RM) olmeca_lang.*
	-$(RM) olmeca_lexer.*
