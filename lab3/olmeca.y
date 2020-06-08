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
static std::string ErrorMessageFunctionDoublyDeclared(std::string);

int g_LoopNestingCounter = 0;

static TSymbolTable* g_TopLevelUserVariableTable = CreateUserVariableTable(NULL);
static TSymbolTable* currentTable = g_TopLevelUserVariableTable;

FILE* out_file;
unsigned int g_tmpVariables = 0;

enum {
  ADD_OPERATOR, SUBTRACT_OPERATOR, MULTY_OPERATOR, DIV_OPERATOR,
  UMINUS_OPERATOR, ASSIGN_OPERATOR,
  MORE_OPERATOR, LESS_OPERATOR, EQUALS_OPERATOR, NOT_EQUALS_OPERATOR,
  GOTO_OPERATOR, GOTO_FALSE_WAY_OPERATOR, GOTO_TRUE_WAY_OPERATOR
};

static std::string funcName = "";
static int g_LastLabelNumber = 0;
static int g_LabelStackPointer = 0;

static int Labels[256];
static void PushLabelNumber(int);
static int PopLabelNumber(void);

int unCodegen(FILE* out_file, int operatorCode, NodeAST* operand, NodeAST* result);
int binCodegen(FILE* out_file, int operatorCode, NodeAST* leftOperand, NodeAST* rightOperand, NodeAST* result);
int gotoCodegen(FILE* out_file, int operatorCode, int labelNumber, NodeAST* optionalExpression);
int labelCodegen(FILE* out_file, int labelNumber);
int getCompareOperator(char* comparison);
int getMulopOperator(char* op);
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
%token 			RETURN  	"return"
%token 			IFX
%token 			COMMA 		","
%type	<node> expr condition condition_head function call_function function_head function_body assignment statement compound_statement statement_list true_way false_way statement_list_tail declaration loop_head loop_condition loop_body loop_statement prog
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
  | %empty {
    $$ = NULL;
  };

statement_list_tail :
  statement_list {
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
    unCodegen(out_file, ASSIGN_OPERATOR, $3, $$);
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
    unCodegen(out_file, ASSIGN_OPERATOR, $4, $$);
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
    unCodegen(out_file, ASSIGN_OPERATOR, $4, $$);
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
    unCodegen(out_file, ASSIGN_OPERATOR, $4, $$);
  }
  | CHAR_TYPE IDENTIFIER ASSIGN expr SEMICOLON {
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
    unCodegen(out_file, ASSIGN_OPERATOR, $4, $$);
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
  condition_head true_way false_way {
    $$ = CreateControlFlowNode(typeIfStatement, $1, $2, $3);
  };

condition_head :
  IF OPENPAREN expr CLOSEPAREN {
    gotoCodegen(out_file, GOTO_FALSE_WAY_OPERATOR, g_LastLabelNumber, $3);
    PushLabelNumber(g_LastLabelNumber);
    ++g_LastLabelNumber;
  };

true_way :
  statement {
    gotoCodegen(out_file, GOTO_OPERATOR, g_LastLabelNumber, NULL);
    labelCodegen(out_file, PopLabelNumber());
    PushLabelNumber(g_LastLabelNumber);
    ++g_LastLabelNumber;
  };

false_way :
  ELSE statement {
    labelCodegen(out_file, PopLabelNumber());
  }
  | %empty %prec IFX {
    labelCodegen(out_file, PopLabelNumber());
  };

function:
  call_function | function_head function_body;

call_function:
  IDENTIFIER OPENPAREN CLOSEPAREN SEMICOLON {
    $$ = CallFunctionNode($1);
    fprintf(out_file, "CALL FUNCTION %s\n", $1->c_str());
  };

function_head:
  FUNCTION IDENTIFIER OPENPAREN CLOSEPAREN {
    fprintf(out_file, "FUNCTION BEGIN %s\n", $2->c_str());
    TSymbolTableElementPtr func = LookupUserVariableTableRecursive(currentTable, *$2);
    if (func != NULL) {
      yyerror(ErrorMessageFunctionDoublyDeclared(*$2));
    } else {
      InsertUserVariableTable(currentTable, *$2, typeFunction, func);
    }
    $$ = CreateAssignmentNode(func, CreateFunctionNode($2));
  };

function_body:
  OPENBRACE statement_list_tail RETURN expr SEMICOLON CLOSEBRACE {
     fprintf(out_file, "FUNCTION END\n");
  };

loop_statement :
  loop_head loop_condition loop_body {
    $$ = CreateControlFlowNode(typeWhileStatement, $1, $2, NULL);
    --g_LoopNestingCounter;
  };

loop_head :
  WHILE {
    labelCodegen(out_file, g_LastLabelNumber);
    PushLabelNumber(g_LastLabelNumber);
    ++g_LastLabelNumber;
  };

loop_condition :
  OPENPAREN expr CLOSEPAREN {
    gotoCodegen(out_file, GOTO_FALSE_WAY_OPERATOR, g_LastLabelNumber, $2);
    PushLabelNumber(g_LastLabelNumber);
    ++g_LastLabelNumber;
  };

loop_body :
  statement {
    int tmpLabelJ = PopLabelNumber();
    int tmpLabelK = PopLabelNumber();

    gotoCodegen(out_file, GOTO_OPERATOR, tmpLabelK, NULL);
    labelCodegen(out_file, tmpLabelJ);
  };

expr :
  expr COMPARE expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot compare different types \n");
      $$ = CreateErrorNode("Comparison error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, $2, $1, $3);
      $$->tmp_index = g_tmpVariables;
      g_tmpVariables++;
      binCodegen(out_file, getCompareOperator($2), $1, $3, $$);
    }
  }
  | expr ADD expr {
    if($1->valueType != $3->valueType) {
      yyerror("Cannot add different types \n");
      $$ = CreateErrorNode("Adding error \n");
    } else {
      $$ = CreateNodeAST(typeBinaryOp, "+", $1, $3);
      $$->tmp_index = g_tmpVariables;
      g_tmpVariables++;
      binCodegen(out_file, ADD_OPERATOR, $1, $3, $$);
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
      $$->tmp_index = g_tmpVariables;
      g_tmpVariables++;
      binCodegen(out_file, SUBTRACT_OPERATOR, $1, $3, $$);
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
      $$->tmp_index = g_tmpVariables;
      g_tmpVariables++;
      binCodegen(out_file, getMulopOperator($2), $1, $3, $$);
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
      $$->tmp_index = g_tmpVariables;
      g_tmpVariables++;
      unCodegen(out_file, UMINUS_OPERATOR, $2, $$);
    }
    }
  | INTEGER_CONST {
    $$ = CreateIntegerNode($1);
    $$->tmp_index = -1;
  }
  | FLOAT_CONST {
    $$ = CreateFloatNode($1);
    $$->tmp_index = -1;
  }
  | STRING_CONST {
    $$ = CreateStringNode($1);
    $$->tmp_index = -1;
  }
  | CHAR_CONST {
    $$ = CreateCharNode($1);
    $$->tmp_index = -1;
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

static std::string ErrorMessageFunctionDoublyDeclared(std::string name) {
  std::string errorDeclaration = "error - Function " + name + " is already declared";
  return errorDeclaration;
}

int unCodegen(FILE* out_file, int operatorCode, NodeAST* operand, NodeAST* result) {
  TSymbolTableElementPtr var;

  if (operatorCode == ASSIGN_OPERATOR) {
    var = (reinterpret_cast<TSymbolTableReference *> (result))->variable;
    fprintf(out_file, "\t%s\t=\t", var->table->data[var->index].name->c_str());
  } else {
    fprintf(out_file, "ASSIGN_%d\t=\t-", result->tmp_index);
  }

  if (operand->nodeType == typeIdentifier) {
    var = (reinterpret_cast<TSymbolTableReference *> (operand))->variable;

    fprintf(out_file, "%s", var->table->data[var->index].name->c_str());
  } else if (operand->tmp_index != -1) {
    fprintf(out_file, "$STATE_%d", operand->tmp_index);
  } else {
    TValueNode *node = reinterpret_cast<TValueNode *>(operand);

    switch (node->nodeType) {
      case typeIntConst:
        fprintf(out_file, "%d", node->iNumber);
        break;
      case typeFloatConst:
        fprintf(out_file, "%g", node->fNumber);
        break;
      case typeStringConst:
        fprintf(out_file, "%s", node->str->c_str());
        break;
      case typeCharConst:
        fprintf(out_file, "%c", node->ch);
        break;
      case typeBinaryOp:
      case typeUnaryOp:
      case typeAssignmentOp:
      case typeIdentifier:
      case typeIfStatement:
      case typeWhileStatement:
      case typeFunctionStatement:
      case typeFunctionCall:
      case typeList:
      case typeError:
        break;
    }
  }

  fprintf(out_file, "\n");
  return 1;
}

int getCompareOperator(char* comparison) {
  if (!strcmp(comparison, ">")) {
    return MORE_OPERATOR;
  }

  if (!strcmp(comparison, "<")) {
    return LESS_OPERATOR;
  }

  if (!strcmp(comparison, "==")) {
    return EQUALS_OPERATOR;
  }

  if (!strcmp(comparison, "!=")) {
    return NOT_EQUALS_OPERATOR;
  }

  return 0;
}

int getMulopOperator(char* op) {
  if (!strcmp(op, "*")) {
    return MULTY_OPERATOR;
  }

  if (!strcmp(op, "/")) {
    return DIV_OPERATOR;
  }

  return 0;
}


int binCodegen(FILE* out_file, int operatorCode, NodeAST* leftOperand, NodeAST* rightOperand, NodeAST* result) {
  fprintf(out_file, "\tSTATE_%u\t=\t", result->tmp_index);

  if (leftOperand->nodeType == typeIdentifier) {
    TSymbolTableElementPtr var = (reinterpret_cast<TSymbolTableReference *> (leftOperand))->variable;

    fprintf(out_file, "%s", var->table->data[var->index].name->c_str());
  } else if (leftOperand->tmp_index != -1) {
    fprintf(out_file, "STATE_%d", leftOperand->tmp_index);
  } else {
    TValueNode *node = reinterpret_cast<TValueNode *>(leftOperand);

    switch (node->nodeType) {
      case typeIntConst:
        fprintf(out_file, "%d", node->iNumber);
        break;
      case typeFloatConst:
        fprintf(out_file, "%g", node->fNumber);
        break;
      case typeStringConst:
        fprintf(out_file, "%s", node->str->c_str());
        break;
      case typeCharConst:
        fprintf(out_file, "%c", node->ch);
        break;
      case typeBinaryOp:
      case typeUnaryOp:
      case typeAssignmentOp:
      case typeIdentifier:
      case typeIfStatement:
      case typeWhileStatement:
      case typeFunctionStatement:
      case typeFunctionCall:
      case typeList:
      case typeError:
        break;
    }
  }

  switch (operatorCode) {
    case ADD_OPERATOR:
      fprintf(out_file, " + ");
      break;
    case SUBTRACT_OPERATOR:
      fprintf(out_file, " - ");
      break;
    case MULTY_OPERATOR:
      fprintf(out_file, " * ");
      break;
    case DIV_OPERATOR:
      fprintf(out_file, " / ");
      break;
    case MORE_OPERATOR:
      fprintf(out_file, " > ");
      break;
    case LESS_OPERATOR:
      fprintf(out_file, " < ");
      break;
    case EQUALS_OPERATOR:
      fprintf(out_file, " == ");
      break;
    case NOT_EQUALS_OPERATOR:
      fprintf(out_file, " != ");
      break;
    }

  if (rightOperand->nodeType == typeIdentifier) {
    TSymbolTableElementPtr var = (reinterpret_cast<TSymbolTableReference *> (rightOperand))->variable;

    fprintf(out_file, "%s", var->table->data[var->index].name->c_str());
  } else if (rightOperand->tmp_index != -1) {
    fprintf(out_file, "STATE_%d", rightOperand->tmp_index);
  } else {
    TValueNode *node = reinterpret_cast<TValueNode *>(rightOperand);

    switch (node->nodeType) {
      case typeIntConst:
        fprintf(out_file, "%d", node->iNumber);
        break;
      case typeFloatConst:
        fprintf(out_file, "%g", node->fNumber);
        break;
      case typeStringConst:
        fprintf(out_file, "%s", node->str->c_str());
        break;
      case typeCharConst:
        fprintf(out_file, "%c", node->ch);
        break;
      case typeBinaryOp:
      case typeUnaryOp:
      case typeAssignmentOp:
      case typeIdentifier:
      case typeIfStatement:
      case typeWhileStatement:
      case typeFunctionStatement:
      case typeFunctionCall:
      case typeList:
      case typeError:
        break;
    }
  }
  fprintf(out_file, "\n");
  return 1;
}

int gotoCodegen(FILE* out_file, int operatorCode, int labelNumber, NodeAST* optionalExpression) {
  if (operatorCode != GOTO_OPERATOR) {
    if (operatorCode == GOTO_FALSE_WAY_OPERATOR)
      fprintf(out_file, "\tIF FALSE WAY ");
    else if(operatorCode == GOTO_TRUE_WAY_OPERATOR)
      fprintf(out_file, "\tIF TRUE WAY ");
    if (optionalExpression->nodeType == typeIdentifier) {
      TSymbolTableElementPtr var = (reinterpret_cast<TSymbolTableReference *> (optionalExpression))->variable;

      fprintf(out_file, "%s ", var->table->data[var->index].name->c_str());
    } else if (optionalExpression->tmp_index != -1) {
      fprintf(out_file, "STATE_%d ", optionalExpression->tmp_index);
    } else {
      TValueNode *node = reinterpret_cast<TValueNode *>(optionalExpression);

      switch (node->nodeType) {
        case typeIntConst:
          fprintf(out_file, "%d ", node->iNumber);
          break;
        case typeFloatConst:
          fprintf(out_file, "%g ", node->fNumber);
          break;
        case typeStringConst:
          fprintf(out_file, "%s ", node->str->c_str());
          break;
      	case typeCharConst:
       	  fprintf(out_file, "%c", node->ch);
          break;
        case typeBinaryOp:
        case typeUnaryOp:
        case typeAssignmentOp:
        case typeIdentifier:
        case typeIfStatement:
        case typeWhileStatement:
        case typeFunctionStatement:
        case typeFunctionCall:
        case typeList:
        case typeError:
          break;
      }
    }
  }
  fprintf(out_file, "\tGO TO LABEL_%d", labelNumber);
  fprintf(out_file, "\n");
  return 1;
}

static void PushLabelNumber(int labelNumber) {
  Labels[g_LabelStackPointer] = labelNumber;
  ++g_LabelStackPointer;
}

static int PopLabelNumber(void) {
  if (g_LabelStackPointer > 0) {
    --g_LabelStackPointer;
    return Labels[g_LabelStackPointer];
  } else {
    g_LabelStackPointer = 0;
    return -1;
  }
}

int labelCodegen(FILE* out_file, int labelNumber) {
  fprintf (out_file, "LABEL_%d:\n", labelNumber);
  return 1;
}

int main(int argc, char *argv[]) {
  Olmeca_driver driver;

//  out_file = fopen("file.out", "w");
//
//  int result = driver.parse(argv[1]);
//  if (result == 0) {
//    std::cout << "Завершено!\n\n";
//  }
//  if (out_file != NULL) {
//    fclose(out_file);
//  }

char* filename = "";

  if (argc > 1)
  {
    for (auto i = 2; i < argc; ++i)
    {
      if (argv[i] == std::string("-ast"))
      {
        driver.AST_dumping = true;
      }
      else if (argv[i] == std::string("-o"))
      {
        if (i + 1 == argc){
          std::cout << "Output filename is not found" << std::endl;
          return 1;
        }
        filename = argv[i+1];
        i++;
      }
    }
    if (filename == "")
    {
      std::cout << "The output file is not specified\n" << "Default name: output" << std::endl;
      filename = "output";
    }

    out_file = fopen(filename, "w");
    if (NULL == out_file)
    {
      std::cout << "Cannot open output file" << filename << std::endl;
      return 1;
    }

    int result = driver.parse(argv[1]);
    if (result == 0)
    {
      std::cout << "Success!\n\n";
    }
    if (out_file != NULL)
    {
      fclose(out_file);
    }

  }
  else {
    std::cout << "Source filename not entered" << std::endl;
  }

  return 0;
}
