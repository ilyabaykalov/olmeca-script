%{
    #include <stdio.h>
    int chars = 0;
%}

%option yylineno
CHAR     [^"\n]
DIGIT    [0-9]
%%

\n                              { chars = 0; }

[ \t\r]                         { chars++; }

{DIGIT}+"."{DIGIT}*         	{ printf("%s\t\t->\t FLOAT\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
{DIGIT}+                    	{ printf("%s\t\t->\t INTEGER\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\'{CHAR}{1}\'               	{ printf("%s\t\t->\t CHAR\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\"{CHAR}*\"                 	{ printf("%s\t\t->\t STRING\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

integer|float|string|char       { printf("%s\t\t->\t DATA TYPE\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
if|else|elif|while              { printf("%s\t\t->\t KEYWORD\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

[a-zA-Z][a-zA-Z0-9]*        	{ printf("%s\t\t->\t IDENTIFIER\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

\+								{ printf("%s\t\t->\t PLUS\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\-								{ printf("%s\t\t->\t MINUS\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\/								{ printf("%s\t\t->\t DIVISION\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\*								{ printf("%s\t\t->\t MULTIPLY\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\=								{ printf("%s\t\t->\t ASSIGN\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\=\=							{ printf("%s\t\t->\t EQUALS\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\<								{ printf("%s\t\t->\t LESS\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\>								{ printf("%s\t\t->\t MORE\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

\(								{ printf("%s\t\t->\t OPENPAREN\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\)								{ printf("%s\t\t->\t CLOSEPAREN\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\{								{ printf("%s\t\t->\t OPENBRACE\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\}								{ printf("%s\t\t->\t CLOSEBRACE\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

\.								{ printf("%s\t\t->\t DOT\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\,								{ printf("%s\t\t->\t COMMA\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\:								{ printf("%s\t\t->\t COLON\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
\;								{ printf("%s\t\t->\t SEMICOLON\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

\/\/\S*[a-zA-Z][a-zA-Z0-9]* 	{ printf("%s\t->\t COMMENT\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }

\"{CHAR}*$                  	{ printf("%s\t\t->\t STRING ERROR\t\t(%d:%d)\n", yytext, yylineno, ++chars); chars += strlen(yytext) - 1; }
.                               { chars++; printf("Error in line %d:%d\n", yylineno, chars); exit(1); }

%%

int yywrap(){  }

int main(int argc, const char* argv[]) {

    char filename [255];

    FILE*file;

    do {
        printf ("path to file: ");
        scanf ("%s", filename);
        file = fopen(filename, "r");
        if (file == NULL) {
            printf ("Can't open file \n");
        }
    } while(file == NULL);

    yyin = file;

    yylex();
    fclose(file);
    printf("\nOlmeca is good\n");
}
