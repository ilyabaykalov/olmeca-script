#ifndef _PARSER_DRIVER_HPP
#define _PARSER_DRIVER_HPP
#include <string>
#include "ast.hpp"
#include "olmeca_lang.hpp"
#define YY_DECL                                                   \
  yy::Olmeca::token_type yylex(yy::Olmeca::semantic_type *yylval, \
                               yy::Olmeca::location_type *yylloc, \
                               Olmeca_driver &driver)
YY_DECL;

class Olmeca_driver {
public:
  Olmeca_driver();
  virtual ~Olmeca_driver();

  int result;

  bool trace_scanning;

  void scan_begin();
  void scan_end();

  int parse(const std::string &f);
  bool trace_parsing;
  bool AST_dumping;

  bool write_xml;
  std::string filename;
  void error(const yy::location &l, const std::string &err_message);
  void error(const std::string &err_message);
};

#endif
