iloc: leitor.l gerador.y
	bison -d gerador.y
	flex leitor.l
	gcc -Wall -o cop gerador.tab.c lex.yy.c -lfl
