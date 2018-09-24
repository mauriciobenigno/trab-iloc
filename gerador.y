%{
#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

char saidaCod[];
int charAtual;
int labelAtual;
FILE *arquivo;

int textoParaInt(char *texto)
{
	int valor = 0;
	texto = strsep(&texto," ");
	printf("palavra: -> %s <- tamanho %d. \r\n",texto,strlen(texto));
	for(int i=0; i<strlen(texto);i++)
	{
		valor+=(int)texto[i];
	}
	valor=valor%500;
	return valor;
}

void iniciaTexto()
{
	arquivo = fopen("iloc.txt", "w");
}

void finalizarTexto()
{	
	fclose(arquivo);
}

%}

%token COMECO FIM
%token IDENTIFICADOR PRINT
%token NUMERO LETRA
%token IF ELSE RECEBE ENDIF FACAATE FIMLACO ENQUANTO FIMENQUANTO
%token IGUAL DIFERENTE MAIOR MAIORIGUAL MENOR MENORIGUAL 
%token VAR SOMA SUB MULT DIV

%%


programa: sequencia_comandos
;

sequencia_comandos: sequencia_comandos comando
| comando
;

comando: atribuicao /* ok */
| desvio /*  IF e IF-ELSE ok - falta repeticao*/
| operacao /* ok */
| impressao /* Falta impressao */
| decisao /* Ok */
| variavel /* Ok */
| COMECO /* Ok */
{
	iniciaTexto();
}
| FIM { finalizarTexto(); }
| {}
;

variavel: VAR NUMERO
{
	printf("funcionou %d",$2);
	fprintf(arquivo, "\r\n");
	fprintf(arquivo, "loadI %d, r50 \r\n", $2);
	fprintf(arquivo, "\r\n");
	fprintf(arquivo, "\r\n");
	fprintf(arquivo, " TESTE ");
	printf("%s   ",saidaCod);
}
| VAR IDENTIFICADOR NUMERO
{
	int pos = textoParaInt($2);
	fprintf(arquivo, "loadI %d, r9 \r\n",$3);
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "store r9, r10 \r\n");
}
| VAR IDENTIFICADOR IDENTIFICADOR
{
	int pos = textoParaInt($2);
	int pos2 = textoParaInt($3);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos);
	fprintf(arquivo, "loadI %d, r10 \r\n",pos2);
	fprintf(arquivo, "load r10, r8 \r\n");
	fprintf(arquivo, "store r8, r9 \r\n");
}
;

atribuicao: IDENTIFICADOR RECEBE NUMERO
{
	/*Basicamente, converto a variavel para endereco de memoria
	Depois guardo esse endereco em R9 e um valor em R10.
	Por fim, guardo o conteudo de R10 no endereco de memoria fornecido em R9 */
	int pos = textoParaInt($1);
	fprintf(arquivo, "loadI %d, r9 \r\n",$3);
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "store r9, r10 \r\n");
	char desbug[500];
	sprintf (desbug, "%s RECEBE %d \r\n",$1,$3);
}
| IDENTIFICADOR RECEBE IDENTIFICADOR
{
	/*Basicamente, converto ambas as variaveis para endereco de memoria
	Depois guardo esse endereco em R9 e R10 respectivamente.
	Carrego o conteudo de R10 em R8, e guardo o conteúdo de R8 no endereco R9*/
	char *nome = $1;
	char *nome2 = $3;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos);
	fprintf(arquivo, "loadI %d, r10 \r\n",pos2);
	fprintf(arquivo, "load r10, r8 \r\n");
	fprintf(arquivo, "store r8, r9 \r\n");
}
;

desvio: IF IDENTIFICADOR 
{ 
	/* Resolve o endereco de memoria */
	char *nome = $2;
	int pos = textoParaInt(nome);
	/* Carrega em R6 o valor de memoria */
	fprintf(arquivo, "loadI %d, r6 \r\n",pos);
	/* Carrega em R5 o valor contido na memoria verificada */
	fprintf(arquivo, "load r6, r5 \r\n");
	/* Se o valor dessa variavel for positiva, então é feito o jump 
	para o valor atual de Label, caso negativa entao o vai para o valor+1 */
	fprintf(arquivo, "cbr r5, L%d: ,L%d: \r\n",labelAtual,(labelAtual+1));
	/* cria o label antes da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	 
	labelAtual++;
} sequencia_comandos{} ENDIF
{
	/* cria o label após da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
}
| IF IDENTIFICADOR 
{
	/* A estrutura if else endif funciona com 3 label, sempre vai cair em if ou else e apos
	o termino de suas tarefas, tanto if quanto else vao saltar para o fim da estrutura */
	/* Resolve o endereco de memoria */
	char *nome = $2;
	int pos = textoParaInt(nome);
	/* Carrega em R6 o valor de memoria */
	fprintf(arquivo, "loadI %d, r6 \r\n",pos);
	/* Carrega em R5 o valor contido na memoria verificada */
	fprintf(arquivo, "load r6, r5 \r\n");
	/* Se o valor dessa variavel for positiva, então é feito o jump 
	para o valor atual de Label, caso negativa entao o vai para o valor+1 */
	fprintf(arquivo, "cbr r5, L%d: ,L%d: \r\n",labelAtual,(labelAtual+1));
	/* cria o label antes da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
} sequencia_comandos ELSE
{
	/* Salta para fora da estrutura condicional apos o termino dos comandos de IF*/
	fprintf(arquivo, "jump L%d: \r\n",(labelAtual+1));
	/* cria o label após da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual); 
	labelAtual++;	
} sequencia_comandos ENDIF
{
	/* Salta para fora da estrutura condicional apos o termino de ELSE */
	fprintf(arquivo, "jump L%d: \r\n",labelAtual);
	/* cria o label após da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
}
| FACAATE IDENTIFICADOR NUMERO
{ 
	/* Resolve o endereco de memoria */
	int pos = textoParaInt($2);
	/* Carrega endereço de memoria da variavel em R3 */
	fprintf(arquivo, "loadI %d, r3 \r\n",pos);
	/* Carrega o valor do contador em R4 */
	fprintf(arquivo, "loadI %d, r4 \r\n",$3);
	/* Salva na memoria o valor 0 para servir de contador */
	fprintf(arquivo, "store 0, r3 \r\n");
	/* Aqui é definido o label de inicio do laço */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
	/* Aqui é feito a recuperacao de valor e comparação do contador com o valor fim*/
	fprintf(arquivo, "loadI %d, r3 \r\n",pos);
	fprintf(arquivo, "load r3, r2 \r\n");
	
}
| FIMLACO
{
	/* Aqui incrementa o registrador r2 e guarda a nova informacao na memoria */
	fprintf(arquivo, "addI r2, 1, r2 \r\n");
	fprintf(arquivo, "store r2, r3 \r\n");
	/* Aqui, caso os valores sejam iguais, é feito jump para o laco e se diferentes 
	e feito para o label posterior */ 
	fprintf(arquivo, "cmp_EQ  r2, r4, r3 \r\n",labelAtual);
	fprintf(arquivo, "cbr r3, L%d: ,L%d: \r\n",(labelAtual-1),labelAtual);
	/* cria o label após da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
}
| ENQUANTO IDENTIFICADOR MENOR NUMERO
{ 
	/* Resolve o endereco de memoria */
	int pos = textoParaInt($2);
	/* Carrega endereço de memoria da variavel em R3 */
	fprintf(arquivo, "loadI %d, r3 \r\n",pos);
	/* Carrega o valor do contador em R4 */
	fprintf(arquivo, "loadI %d, r4 \r\n",$4);
	/* Salva na memoria o valor 0 para servir de contador */
	fprintf(arquivo, "store 0, r3 \r\n");
	/* Aqui é definido o label de inicio do laço */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
	/* Aqui é feito a recuperacao de valor e comparação do contador com o valor fim*/
	fprintf(arquivo, "loadI %d, r3 \r\n",pos);
	fprintf(arquivo, "load r3, r2 \r\n");
	
} FIMENQUANTO
{
	/* Aqui incrementa o registrador r2 e guarda a nova informacao na memoria */
	fprintf(arquivo, "addI r2, 1, r2 \r\n");
	fprintf(arquivo, "store r2, r3 \r\n");
	/* Aqui, caso os valores sejam iguais, é feito jump para o laco e se diferentes 
	e feito para o label posterior */ 
	fprintf(arquivo, "cmp_EQ  r2, r4, r3 \r\n",labelAtual);
	fprintf(arquivo, "cbr r3, L%d: ,L%d: \r\n",(labelAtual-1),labelAtual);
	/* cria o label após da sequencia de comandos */
	fprintf(arquivo, "L%d: \r\n",labelAtual);
	labelAtual++;
}
;

operacao: IDENTIFICADOR RECEBE IDENTIFICADOR SOMA IDENTIFICADOR 
{ 
	char *nome = $1;
	char *nome2 = $3;
	char *nome3 = $5;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores que contem endereco de memoria das variais */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3); 
	/* Carregando valores a serem somados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a soma e guarda o valor no endereco de R10 */
	fprintf(arquivo, "add r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR RECEBE IDENTIFICADOR SUB IDENTIFICADOR 
{
 	char *nome = $1;
	char *nome2 = $3;
	char *nome3 = $5;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores que contem endereco de memoria das variais */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos); 
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2); 
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3); 
	/* Carregando valores a serem somados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a subtracao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "sub r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR RECEBE IDENTIFICADOR DIV IDENTIFICADOR 
{
	char *nome = $1;
	char *nome2 = $3;
	char *nome3 = $5;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores que contem endereco de memoria das variais */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3); 
	/* Carregando valores a serem somados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a divisao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "div r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR RECEBE IDENTIFICADOR MULT IDENTIFICADOR 
{
	char *nome = $1;
	char *nome2 = $3;
	char *nome3 = $5;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores que contem endereco de memoria das variais */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem somados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a multiplicacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "mult r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");	
}
| IDENTIFICADOR RECEBE IDENTIFICADOR SOMA NUMERO 
{
	char *nome = $1;
	char *nome2 = $3;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a soma imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "addI r8, %d, r7 \r\n",$5);
	fprintf(arquivo, "store r7, r10 \r\n");
	
}
| IDENTIFICADOR RECEBE IDENTIFICADOR SUB NUMERO 
{ 
	char *nome = $1;
	char *nome2 = $3;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a subtracao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "subI r8, %d, r7 \r\n",$5); 
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE IDENTIFICADOR DIV NUMERO 
{ 
	char *nome = $1;
	char *nome2 = $3;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a divisao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "divI r8, %d, r7 \r\n",$5);
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE IDENTIFICADOR MULT NUMERO 
{ 
	char *nome = $1;
	char *nome2 = $3;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2); 
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a multiplicacao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "multI r8, %d, r7 \r\n",$5); 
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE NUMERO SOMA NUMERO 
{
	char *nome = $1;
	int pos = textoParaInt(nome);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r9 \r\n",$3); 
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a soma imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "addI r8, %d, r7 \r\n",$5);
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE NUMERO SUB NUMERO 
{
	char *nome = $1;
	int pos = textoParaInt(nome);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r9 \r\n",$3);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8\r\n");
	/* Realiza a subtracao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "subI r8, %d, r7",$5); 
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE NUMERO DIV NUMERO 
{
	char *nome = $1;
	int pos = textoParaInt(nome);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r9 \r\n",$3);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a divisao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "divI r8, %d, r7 \r\n",$5);
	fprintf(arquivo, "store r7, r10 \r\n");
}
| IDENTIFICADOR RECEBE NUMERO MULT NUMERO 
{
	char *nome = $1;
	int pos = textoParaInt(nome);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r9 \r\n",$3);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r8 \r\n");
	/* Realiza a multiplicacao imediata e guarda o valor no endereco de R10 */
	fprintf(arquivo, "multI r8, %d, r7 \r\n",$5);
	fprintf(arquivo, "store r7, r10 \r\n");
}
;

impressao: PRINT IDENTIFICADOR
{	
	printf("%s\n",$2);
	printf("%s",saidaCod);
	/*
	char *nome = $2;
	int pos = textoParaInt(nome);
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "load r10, r9 \r\n");
	fprintf(arquivo, "printf(\" %d \",r[9]);\r\n");
	*/
}
| PRINT NUMERO
{
	printf("%d\n",$2);
	printf("%s",saidaCod);
}
;


decisao: IDENTIFICADOR IDENTIFICADOR MAIOR IDENTIFICADOR
{
	/* São passados 3 variaveis, e calculados seus enderecos de memoria
	o endereco de memoria sao carregados nos registradores R10, R9 e R8.
	Sao carregados os valores de memoria que estavam em R8 e R9 e por
	fim sao comparados e o resultado armazenado em R5. */
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores que contem endereco de memoria das variais */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_GT r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MAIOR NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_GT r7, r8, r6 \r\n");
	fprintf(arquivo, "store r6, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MAIORIGUAL IDENTIFICADOR
{
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */	
	fprintf(arquivo, "cmp_GE r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MAIORIGUAL NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_GE r7, r8, r6\r\n");
	fprintf(arquivo, "store r6, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MENOR IDENTIFICADOR
{
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */	
	fprintf(arquivo, "cmp_LT r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MENOR NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_LT r7, r8, r6\r\n");
	fprintf(arquivo, "store r6, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MENORIGUAL IDENTIFICADOR
{
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */	
	fprintf(arquivo, "cmp_LE r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR MENORIGUAL NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_LE r7, r8, r6 \r\n");
	fprintf(arquivo, "store r6, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR IGUAL IDENTIFICADOR
{
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos); 
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */	
	fprintf(arquivo, "cmp_EQ r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR IGUAL NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_EQ r7, r8, r6 \r\n");
	fprintf(arquivo, "store r6, r10 \r\n");	
}
| IDENTIFICADOR IDENTIFICADOR DIFERENTE IDENTIFICADOR
{
	char *nome = $1;
	char *nome2 = $2;
	char *nome3 = $4;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	int pos3 = textoParaInt(nome3);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	fprintf(arquivo, "loadI %d, r8 \r\n",pos3);
	/* Carregando valores a serem comparados */
	fprintf(arquivo, "load r8, r6 \r\n");
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */	
	fprintf(arquivo, "cmp_NE r6, r7, r5 \r\n");
	fprintf(arquivo, "store r5, r10 \r\n");
}
| IDENTIFICADOR IDENTIFICADOR DIFERENTE NUMERO
{
	char *nome = $1;
	char *nome2 = $2;
	int pos = textoParaInt(nome);
	int pos2 = textoParaInt(nome2);
	/* Valores de memoria */
	fprintf(arquivo, "loadI %d, r10 \r\n",pos);
	fprintf(arquivo, "loadI %d, r9 \r\n",pos2);
	/* Valor imediato */
	fprintf(arquivo, "loadI %d, r8 \r\n",$4);
	/* Carregando valor a ser comparado */
	fprintf(arquivo, "load r9, r7 \r\n");
	/* Realiza a comparacao e guarda o valor no endereco de R10 */
	fprintf(arquivo, "cmp_NE r7, r8, r6 \r\n");
	fprintf(arquivo, "store r6, r10 \r\n");
}
;



%%
