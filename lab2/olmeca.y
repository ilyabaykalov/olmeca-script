%{
#include <cstdio>
#include <cstdlib>
#include <string>
#include <cstring>
#include <algorithm>
#include <fstream>

#include "ast.hpp"
#include "symtable.hpp"
#include "olmeca_driver.hpp"

%}

%skeleton "lalr1.cc"
%require  "3.0"
%defines
%define api.parser.class {Olmeca}
%define parse.assert

%code requires {
  class Olmeca_driver;
}
%param { Olmeca_driver& driver }


%locations
%initial-action {
  @$.begin.filename = @$.end.filename = &driver.filename;
};

%define parse.trace
%define parse.error verbose

%code {

#undef yyerror
#define yyerror driver.error

static std::string ErrorMessageVariableNotDeclared(std::string);
static std::string ErrorMessageVariableDoublyDeclared(std::string);

int g_LoopNestingCounter = 0;

static TSymbolTable* g_TopLevelUserVariableTable = CreateUserVariableTable(NULL);
static TSymbolTable* currentTable = g_TopLevelUserVariableTable;
}

%union {
  NodeAST* node;
  float fNumber;
  int iNumber;
  std::string* string;
  std::string* identifier;
  char comparison[3];
  char ch[1];
}

%token 			EOFILE 0 	"end of file"
%token 			INTEGER_TYPE 	"int"
%token	<iNumber>	INTEGER_CONST  	"integer"
%token 			FLOAT_TYPE 	"float type"
%token	<fNumber> 	FLOAT_CONST  	"float"
%token 			STRING_TYPE
%token 			CHAR_TYPE
%token	<string> 	STRING_CONST
%token	<ch> 		CHAR_CONST
%token 			ASSIGN 		"="
%token	<identifier> 	IDENTIFIER 	"name"
%token 			SEMICOLON  	";"
%token 			COLON  		":"
%token 			ADD  		"+"
%token 			SUBSTRACT 	"-"
%token	<comparison>   	MULOPERATOR     "mulop"
%token	<comparison> 	COMPARE 	"compare"
%token 			OPENPAREN 	"("
%token 			CLOSEPAREN 	")"
%token 			OPENBRACE 	"{"
%token 			CLOSEBRACE	"}"
%token 			IF 		"if"
%token 			ELSE 		"else"
%token 			WHILE 		"while"
%token 			FUNCTION 	"function"
%token 			IFX
%token 			COMMA 		","
%type	<node> expr condition function assignment statement compound_statement statement_list statement_list_tail declaration loop_head loop_statement prog
%nonassoc IFX
%nonassoc ELSE

%right 	ASSIGN
%left 	COMPARE
%left 	ADD SUBSTRACT
%left 	MULOPERATOR
%right 	UMINUS

%start prog

%printer { yyoutput << $$; } <*>;

%destructor { delete $$; } IDENTIFIER
%%

prog :
  statement_list {
    if(driver.AST_dumping) {
      PrintAST($1, 0);
    }
    driver.result = 0;
  };

statement_list :
  statement statement_list_tail {
    if($2 == NULL) {
      $$ = $1;
    } else {
      $$ = CreateNodeAST(typeList, "Stmt List", $1, $2);
    }
  }

statement_list_tail :
  %empty {
    $$ = NULL;
  }
  | statement_list {
    $$ = $1;
  };

statement :
  assignment
  | condition
  | declaration
  | compound_statement
  | loop_statement
  | function;

compound_statement :
  OPENBRACE {
    currentTable = CreateUserVariableTable(currentTable);
  }
  statement_list
  CLOSEBRACE {
    $$ = $3;
    HideUserVariableTable(currentTable); currentTable = currentTable->parentTable;
  };

assignment :
  IDENTIFIER ASSIGN expr SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$1);
    if (NULL == var) {
      yyerror(ErrorMessageVariableNotDeclared(*$1));
    } else if ($3->valueType != var->table->data[var->index].valueType) {
      yyerror("warning - types incompatible in assignment \n");
    }
    $$ = CreateAssignmentNode(var, $3);
  }
  | INTEGER_TYPE IDENTIFIER ASSIGN expr SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeInt, var);
    }
    if ($4->valueType != var->table->data[var->index].valueType) {
      yyerror("warning - types incompatible in assignment \n");
    }
    $$ = CreateAssignmentNode(var, $4);
  }
  | FLOAT_TYPE IDENTIFIER ASSIGN expr SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeFloat, var);
    }
    if ($4->valueType != var->table->data[var->index].valueType) {
      yyerror("warning - types incompatible in assignment \n");
    }
    $$ = CreateAssignmentNode(var, $4);
  }
  | STRING_TYPE IDENTIFIER ASSIGN expr SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeString, var);
    }
    if ($4->valueType != var->table->data[var->index].valueType) {
      yyerror("warning - types incompatible in assignment \n");
    }
    $$ = CreateAssignmentNode(var, $4);
  }| CHAR_TYPE IDENTIFIER ASSIGN expr SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeChar, var);
    }
    if ($4->valueType != var->table->data[var->index].valueType) {
      yyerror("warning - types incompatible in assignment \n");
    }
    $$ = CreateAssignmentNode(var, $4);
  };

declaration :
  INTEGER_TYPE IDENTIFIER SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeInt, var);
    }
    $$ = CreateAssignmentNode(var, CreateIntegerNode(0));
  }
  | FLOAT_TYPE IDENTIFIER SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeFloat, var);
    }
    $$ = CreateAssignmentNode(var, CreateFloatNode(0.0f));
  }
  | STRING_TYPE IDENTIFIER SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeString, var);
    }
    $$ = CreateAssignmentNode(var, CreateStringNode(NULL));
  }
  | CHAR_TYPE IDENTIFIER SEMICOLON {
    TSymbolTableElementPtr var = LookupUserVariableTable(currentTable, *$2);
    if(var != NULL) {
      yyerror(ErrorMessageVariableDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeChar, var);
    }
    $$ = CreateAssignmentNode(var, CreateCharNode(NULL));
  };

condition :
  IF OPENPAREN expr CLOSEPAREN statement %prec IFX {
    $$ = CreateControlFlowNode(typeIfStatement, $3, $5, NULL);
  }
  | IF OPENPAREN expr CLOSEPAREN statement ELSE statement {
    $$ = CreateControlFlowNode(typeIfStatement, $3, $5, $7);
  };

function :
  FUNCTION IDENTIFIER OPENPAREN CLOSEPAREN OPENBRACE statement_list CLOSEBRACE {
    TSymbolTableElementPtr funcId = LookupUserVariableTableRecursive(currentTable, *$2);
    if (NULL != funcId) {
          yyerror(ErrorMessageVariableNotDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeFunction, funcId);
    }
    $$ = CreateFunctionNode(typeFunctionStatement, $2, $6);
  };

loop_statement :
  loop_head statement {
    $$ = CreateControlFlowNode(typeWhileStatement, $1, $2, NULL);
    --g_LoopNestingCounter;
  };

loop_head :
  WHILE OPENPAREN expr CLOSEPAREN {
    $$ = $3;
    ++g_LoopNestingCounter;
  };

expr :
  expr COMPARE expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot compare different types \n");
      $$ = CreateErrorNode("Comparison error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, $2, $1, $3);
    }
  }
  | expr ADD expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot add different types \n");
      $$ = CreateErrorNode("Adding error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, "+", $1, $3);
    }
  }
  | expr SUBSTRACT expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot substract different types \n");
      $$ = CreateErrorNode("Substract error \n");
    } else if ($1->valueType == typeString ||  $3->valueType == typeString) {
      yyerror("Cannot substract string types \n");
      $$ = CreateErrorNode("Substract error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, "-", $1, $3);
    }
  }
  | expr MULOPERATOR expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot mulop different types \n");
      $$ = CreateErrorNode("Mulop error \n");
    } else if ($1->valueType == typeString ||  $3->valueType == typeString) {
      yyerror("Cannot substract string types \n");
      $$ = CreateErrorNode("Substract error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, $2, $1, $3);
    }
  }
  | OPENPAREN expr CLOSEPAREN {
    $$ = $2;
  }
  | SUBSTRACT expr %prec UMINUS {
    if ($2->valueType == typeString) {
      yyerror("Cannot unary substract string types \n");
      $$ = CreateErrorNode("Unary substract error \n");
    } else {
      $$ = CreateNodeAST(typeUnaryOp, "-", $2, NULL);
    }
    }
  | INTEGER_CONST {
    $$ = CreateIntegerNode($1);
  }
  | FLOAT_CONST {
    $$ = CreateFloatNode($1);
  }
  | STRING_CONST {
    $$ = CreateStringNode($1);
  }
  | CHAR_CONST {
    $$ = CreateCharNode($1);
  }
  | IDENTIFIER {
    TSymbolTableElementPtr var = LookupUserVariableTableRecursive(currentTable, *$1);
    if (NULL == var) {
      yyerror(ErrorMessageVariableNotDeclared(*$1));
    }
    $$ = CreateReferenceNode(var);
  };

%%
void yy::Olmeca::error(const location_type& l, const std::string& m) {
  driver.error(l, m);
}

static std::string ErrorMessageVariableNotDeclared(std::string name) {
  std::string errorDeclaration = "error - Variable " + name + " isn't declared";
  return errorDeclaration;
}

static std::string ErrorMessageVariableDoublyDeclared(std::string name) {
  std::string errorDeclaration = "error - Variable " + name + " is already declared";
  return errorDeclaration;
}

