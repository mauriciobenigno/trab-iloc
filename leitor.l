%option yylineno
%{
#include <stdio.h>
#include "gerador.tab.h" 
%}

%%

"Var" { return VAR; }
"Print" { return PRINT; }
"==" { return IGUAL; }
"!=" { return DIFERENTE; }
">" { return MAIOR; }
"<" { return MENOR; }
"+" { return SOMA; }
"-" { return SUB; }
"*" { return MULT; }
"/" { return DIV; }
"=" { return RECEBE; }
"Se" { return IF; }
"SeNao" { return ELSE; }
"FimSe" { return ENDIF; }
"FacaAte" { return FACAATE; }
"FimLaco" { return FIMLACO; }
"Enquanto" { return ENQUANTO; }
"FimEnquanto" { return FIMENQUANTO; }
"Main" { return COMECO; }
"FimMain" { return FIM; }



[0-9]+ { yylval = atoi(yytext); return NUMERO; }
[aA-zZ]+[0-9]+ { yylval = yytext; return IDENTIFICADOR; }

[ \t] { /* Espaço */ }
[ \0] { /* Fim de linha */ }
[ \n] { /* Pula linha */ }
[ \r] { /* Enter */ }
. { printf("Caractere invalido encontrado: %i\n", *yytext); }
%%

main(int argc, char **argv)
{
	if(argc > 1){
		if(!(yyin = fopen(argv[1], "r"))) {
			perror(argv[1]);
			return (1);
		}
	}
	yyparse();
}

yyerror(const char *msg)
{
	printf("%d: %s at '%s'\n",yylineno,msg,yytext);
}
