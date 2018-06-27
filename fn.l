dreal	([0-9]*\.[0-9]+)
ereal	([0-9]*\.[0-9]+[eE][+-]?[0-9]+)
int	[0-9]+
real	({dreal}|{ereal}|{int})
acos	[Aa][Cc][Oo][Ss]
asin	[Aa][Ss][Ii][Nn]
atan	[Aa][Tt][Aa][Nn]
cos	[Cc][Oo][Ss]
sin	[Ss][Ii][Nn]
tan	[Tt][Aa][Nn]
exp	[Ee][Xx][Pp]
log	[Ll][Oo][Gg]
log10	{log}10
sqrt	[Ss][Qq][Rr][Tt]
ceil	[Cc][Ee][Ii][Ll]
fabs	[Ff][Aa][Bb][Ss]
floor	[Ff][Ll][Oo][Oo][Rr]
function	(cos|sin|tan|acos|asin|atan|exp|log|log10|sqrt|ceil|fabs|floor)
%{
#include <stdio.h>
#include <string.h>
#include <math.h>
#include "fn.h"
#include "fn_.h"

%}
%%
{real}		{
			Cats(yytext);
			yylval = new_mem(yytext);
			return INDEX;
		}
sin		{
			Cats(yytext);
			return yylval = SIN;
		}
cos		{
			Cats(yytext);
			return yylval = COS;
		}
tan		{
			Cats(yytext);
			return yylval = TAN;
		}
[a-z]		{
			Cats(yytext);
			yylval = *yytext-'a';
			return INDEX;
		}
[A-Z]		{	
			Cats(yytext);
			yylval = *yytext-'A';
			return INDEX;
		}
("+"|"-"|"/"|"*"|"^")	{
			Cats(yytext);
		yylval = *yytext;
		return *yytext;
			}
("("|")")		{
			Cats(yytext);
			return *yytext;
			}
\n		return '\n';
.		;
%%
static int new_mem(char *s) {
  if (memn >= MAXMEM) yyerror("new_mem");
  mem[memn] = atof(s);
  return memn++;
}
static int new_code(int i) {
  if (coden >= MAXCODE) yyerror("new_code");
  code[coden] = i;
  return coden++;
}

unsigned char Catstring[MAX_CATSTRING];
void Cats(unsigned char s[])
{
strcat((char*)Catstring, (char*)s);
}
