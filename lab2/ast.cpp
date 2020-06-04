#include <cstdio>
#include <cstdlib>
#include <cstdarg>
#include <cstring>
#include <cmath>
#include <iostream>
#include <fstream>
#include <sstream>

#include "ast.hpp"

NodeAST *CreateNodeAST(NodeTypeEnum nodeType, const char *opValue, NodeAST *left, NodeAST *right) {
  NodeAST *a = new NodeAST;

  a->nodeType = nodeType;
  strcpy(a->opValue, opValue);
  a->valueType = left->valueType;
  a->left = left;
  a->right = right;

  return a;
}

NodeAST *CreateIntegerNode(int integerValue) {
  TValueNode *a = new TValueNode;

  a->nodeType = typeIntConst;
  a->valueType = typeInt;
  a->iNumber = integerValue;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateFloatNode(float floatValue) {
  TValueNode *a = new TValueNode;

  a->nodeType = typeFloatConst;
  a->valueType = typeFloat;
  a->fNumber = floatValue;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateStringNode(std::string *str) {
  TValueNode *a = new TValueNode;

  a->nodeType = typeStringConst;
  a->valueType = typeString;
  if (str == NULL) {
    str = new std::string("");
  }
  a->str = str;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateCharNode(char *c) {
  TValueNode *a = new TValueNode;

  a->nodeType = typeCharConst;
  a->valueType = typeChar;
  if (c == NULL) {
    c = new char();
  }
  a->ch = *c;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateErrorNode(const char *error) {
  TErrorNode *e = new TErrorNode;

  e->nodeType = typeError;
  if (error == NULL) {
    e->error = new std::string("");
  } else {
    e->error = new std::string(error);
  }

  return reinterpret_cast<NodeAST *>(e);
}

NodeAST *CreateControlFlowNode(NodeTypeEnum nodeType, NodeAST *condition, NodeAST *trueBranch, NodeAST *elseBranch) {
  TControlFlowNode *a = new TControlFlowNode;

  a->nodeType = nodeType;
  a->condition = condition;
  a->trueBranch = trueBranch;
  a->elseBranch = elseBranch;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateFunctionNode(std::string *funcName, NodeAST *funcBody, int returnedValue) {
  TFunctionNode *a = new TFunctionNode;

  a->nodeType = typeFunctionStatement;
  a->funcBody = funcBody;

  TValueNode *name = new TValueNode;

  name->nodeType = typeStringConst;
  name->valueType = typeString;
  name->str = funcName;

  a->funcName = name;

  TValueNode *retVal = new TValueNode;

  retVal->nodeType = typeIntConst;
  retVal->valueType = typeInt;
  retVal->iNumber = returnedValue;

  a->returnedValue = retVal;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CallFunctionNode(std::string *funcName) {
TFunctionNode *a = new TFunctionNode;

  a->nodeType = typeFunctionCall;

  TValueNode *name = new TValueNode;

  name->nodeType = typeStringConst;
  name->valueType = typeString;
  name->str = funcName;

  a->funcName = name;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateReferenceNode(TSymbolTableElementPtr symbol) {
  TSymbolTableReference *a = new TSymbolTableReference;

  a->nodeType = typeIdentifier;
  a->variable = symbol;
  a->valueType = symbol->table->data[symbol->index].valueType;

  return reinterpret_cast<NodeAST *>(a);
}

NodeAST *CreateAssignmentNode(TSymbolTableElementPtr symbol, NodeAST *rightValue) {
  TAssignmentNode *a = new TAssignmentNode;

  a->nodeType = typeAssignmentOp;
  a->variable = symbol;
  a->value = rightValue;

  return reinterpret_cast<NodeAST *>(a);
}

void FreeAST(NodeAST *a) {
  if (NULL == a)
    return;
  switch (a->nodeType) {
    case typeBinaryOp:
    case typeList:
        FreeAST(a->right);
    case typeUnaryOp:
        FreeAST(a->left);
    case typeStringConst:
    case typeIntConst:
    case typeFloatConst:
    case typeIdentifier:
        break;
    case typeAssignmentOp:
        delete ((TAssignmentNode *)a)->value;
        break;
    case typeIfStatement:
    case typeWhileStatement:
        delete ((TControlFlowNode *)a)->condition;
        if (((TControlFlowNode *)a)->trueBranch)
            FreeAST(((TControlFlowNode *)a)->trueBranch);
        if (((TControlFlowNode *)a)->elseBranch)
            FreeAST(((TControlFlowNode *)a)->elseBranch);
        break;

    default:
        std::cout << "internal error: free bad node " << a->nodeType << std::endl;
  }

  delete a;
}

void PrintAST(NodeAST *a, int level) {
  try {
    std::cout << std::string(level, ' ');

    if (a == NULL) {
      std::cout << "NULL" << std::endl;
      return;
    }

    switch (a->nodeType) {
        case typeError:
          std::cout << "error occurred: " << *(((TErrorNode *)a)->error);
          break;

        case typeIntConst:
          std::cout << "integer " << ((TValueNode *)a)->iNumber << std::endl;
          break;

        case typeFloatConst:
          std::cout << "float " << ((TValueNode *)a)->fNumber << std::endl;
          break;

        case typeStringConst:
          std::cout << "string " << *(((TValueNode *)a)->str) << std::endl;
          break;

        case typeCharConst:
          std::cout << "char " << (((TValueNode *)a)->ch) << std::endl;
          break;

        case typeBinaryOp:
          std::cout << "operation " << a->opValue << std::endl;
          PrintAST(a->left, level + 1);
          PrintAST(a->right, level + 1);
          break;

        case typeIdentifier:
        case typeList:
          std::cout << "var ";
          PrintAST(a->left, level + 1);
          PrintAST(a->right, level + 1);
          break;

        case typeUnaryOp:
          std::cout << "unaryOp " << a->opValue << std::endl;
          PrintAST(a->left, level + 1);
          break;

        case typeAssignmentOp: {
          TSymbolTableElementPtr tmp = ((TAssignmentNode *)a)->variable;

          if (NULL != tmp) {
            std::cout << *(tmp->table->data[tmp->index].name) << " =";
          } else {
            std::cout << "(bad reference)";
          }

          std::cout << std::endl;
          PrintAST(((TAssignmentNode *)a)->value, level);
          return;
        }

        case typeIfStatement:
          std::cout << "if " << std::endl;

          PrintAST(((TControlFlowNode *)a)->condition, level);

          if (((TControlFlowNode *)a)->trueBranch) {
            std::cout << std::string(2 * level, ' ');
            std::cout << "true way" << std::endl;

            PrintAST(((TControlFlowNode *)a)->trueBranch, level + 1);
          }
          if (((TControlFlowNode *)a)->elseBranch) {
            std::cout << std::string(2 * level, ' ');
            std::cout << "false way" << std::endl;

            PrintAST(((TControlFlowNode *)a)->elseBranch, level + 1);
          }
          break;

        case typeWhileStatement:
          std::cout << "while loop" << std::endl;
          PrintAST(((TControlFlowNode *)a)->condition, level);

          if (((TControlFlowNode *)a)->trueBranch) {
            std::cout << std::string(2 * level, ' ');
            std::cout << "body" << std::endl;

            PrintAST(((TControlFlowNode *)a)->trueBranch, level + 1);
          }
          break;

        case typeFunctionStatement:
          std::cout << "function " << *(((TFunctionNode *)a)->funcName)->str << std::string(2 * level, ' ') << std::endl;
          PrintAST(((TFunctionNode *)a)->funcBody, level);
          break;

        case typeFunctionCall:
          std::cout << "call function " << *((((TFunctionNode *)a)->funcName)->str) << std::string(2 * level, ' ') << std::endl;
          break;
    }
  }
  catch (const std::exception &e) {}
  return;
}
