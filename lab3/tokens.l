%{
    #if defined _WIN32
    #include <io.h>
    #include <io.h>
    #endif

    #ifdef MSVC
    #define  isatty _isatty
    #endif

    #include <ctype.h>
    #include "ast.hpp"
    #include "olmeca_lang.hpp"
    #include "olmeca_driver.hpp"

    #undef yywrap
    #define yywrap() 1

    yy::location loc;

    typedef yy::Olmeca::token token;
    typedef yy::Olmeca::token_type token_type;

    #define yyterminate() return token::EOFILE
%}

%option noyywrap nounput noinput noyylineno

EXP	([Ee][-+]?[0-9]+)
CHAR     [^"\n]
DIGIT    [0-9]
%{
  #define YY_USER_ACTION  loc.columns(yyleng);
%}

%%

%{
  loc.step();
%}

\n                              { loc.lines(1); loc.step(); }

[ \t]+                          { loc.step(); }

<<EOF>>                         { return token::EOFILE; }

integer                         { return token::INTEGER_TYPE; }
float                           { return token::FLOAT_TYPE; }
string                          { return token::STRING_TYPE; }
char                            { return token::CHAR_TYPE; }

if                              { return token::IF; }
else                            { return token::ELSE; }
while                           { return token::WHILE; }
function                        { return token::FUNCTION; }
return                          { return token::RETURN; }

\;                              { return token::SEMICOLON;}
\:                              { return token::COLON;}
\,                              { return token::COMMA; }

\(                              { return token::OPENPAREN;}
\)                              { return token::CLOSEPAREN;}

\{                              { return token::OPENBRACE;}
\}                              { return token::CLOSEBRACE;}

\=                              { return token::ASSIGN; }
\+                              { return token::ADD; }
\-                              { return token::SUBSTRACT; }
\*|\/                           {
                                  strcpy(yylval->comparison, yytext);
                                  return token::MULOPERATOR;
                                }
">"|"<"|"=="|"!="               {
                                  strcpy(yylval->comparison, yytext);
                                  return token::COMPARE;
                                }

\/\/.*\n                        {}

[a-zA-Z][a-zA-Z0-9]*            {
                                  yylval->identifier= new std::string(yytext, yyleng);
                                  return token::IDENTIFIER;
                                }

{DIGIT}+                        {
                                  yylval->iNumber = atoi(yytext);
                                  return token::INTEGER_CONST;
                                }

{DIGIT}+"."{DIGIT}*             {
                                  yylval->fNumber = atof(yytext);
                                  return token::FLOAT_CONST;
                                }

\'{CHAR}\'                      {
                                  std::string str(yytext);
                                  yylval->ch[0] = str[1];
                                  return token::CHAR_CONST;
                                }

\"{CHAR}*\"                     {
                                  yylval->string = new std::string(yytext, yyleng);
                                  return token::STRING_CONST;
                                }

\"{CHAR}*$                      {
                                  std::string tmp(yytext);
                                  driver.error(loc, "unfinished string literal " + tmp);
                                  return static_cast<token_type>(*yytext);
                                }


.	                            {
                                  std::string tmp(yytext);
                                  driver.error(loc, "WTF symbol, bro!? " + tmp);
                                  return static_cast<token_type>(*yytext);
                                }
%%


void Olmeca_driver::scan_begin() {
  if (filename.empty() || filename == "-")
    yyin = stdin;
  else if (!(yyin = fopen(filename.c_str(), "r"))) {
    error("cannot open " + filename + ": " + strerror(errno));
    exit(EXIT_FAILURE);
  }
}

void Olmeca_driver::scan_end() {
  fclose(yyin);
}
