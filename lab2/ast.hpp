#ifndef _ABSTRACT_SYNTAX_TREE_HPP
#define _ABSTRACT_SYNTAX_TREE_HPP

#include <string>

#include "subexpression.hpp"

typedef enum {
  typeBinaryOp,
  typeUnaryOp,
  typeAssignmentOp,
  typeIntConst,
  typeFloatConst,
  typeStringConst,
  typeCharConst,
  typeIdentifier,
  typeIfStatement,
  typeWhileStatement,
  typeList,
  typeError
} NodeTypeEnum;

typedef struct TAbstractSyntaxTreeNode {
  NodeTypeEnum nodetype;
  SubexpressionValueTypeEnum valueType;
  char opValue[3];
  struct TAbstractSyntaxTreeNode *left;
  struct TAbstractSyntaxTreeNode *right;
} NodeAST;

typedef struct {
  NodeTypeEnum nodetype;
  NodeAST *condition;
  NodeAST *trueBranch;
  NodeAST *elseBranch;
} TControlFlowNode;

typedef struct {
  NodeTypeEnum nodetype;
  SubexpressionValueTypeEnum valueType;
  union {
    int iNumber;
    float fNumber;
    std::string *str = new std::string("");
    char ch;
  };
} TValueNode;

#ifndef _SYMBOL_TABLE_HPP
#include "symtable.hpp"
#endif

typedef struct {
  NodeTypeEnum nodetype;
  SubexpressionValueTypeEnum valueType;
  TSymbolTableElementPtr variable;
} TSymbolTableReference;

typedef struct {
  NodeTypeEnum nodetype;
  TSymbolTableElementPtr variable;
  NodeAST *value;
} TAssignmentNode;

typedef struct {
  NodeTypeEnum nodeType;
  std::string *error = new std::string("");
} TErrorNode;

NodeAST *CreateNodeAST(NodeTypeEnum cmptype, const char *opValue, NodeAST *left, NodeAST *right);
NodeAST *CreateIntegerNode(int integerValue);
NodeAST *CreateFloatNode(float floatValue);
NodeAST *CreateStringNode(std::string *str);
NodeAST *CreateCharNode(char *ch);
NodeAST *CreateErrorNode(const char*error);

NodeAST *CreateControlFlowNode(NodeTypeEnum Nodetype, NodeAST *condition, NodeAST *trueBranch, NodeAST *elseBranch);
NodeAST *CreateReferenceNode(TSymbolTableElementPtr symbol);
NodeAST *CreateAssignmentNode(TSymbolTableElementPtr symbol, NodeAST *rightValue);

void FreeAST(NodeAST *);

void PrintAST(NodeAST *aTree, int level);
#endif
