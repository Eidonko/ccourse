%{
# include <stdio.h>
# include <ctype.h>
# include <string.h>
# include <stdarg.h>
# include <math.h>

# include "fn.h"
int fndebug;
double mem[MAXMEM];
int    code[MAXCODE];
int memn, coden;

int yyerror(char *s) { fprintf(stderr, "Error: %s\n", s); }
%}

%token INDEX

/* precedence/associativity */
%left '+' '-'
%left '*' '/'
%left '^'
%left SIN ACOS ASIN ATAN LOG LOG10 EXP COS TAN SQRT CEIL FABS FLOOR
%left UMINUS 

/* %left UMINUS */

%%	/* rules */
line	: 	expr	'\n'
		{
		if (fndebug)
			printf("line: line expr '\\n'\n");
		return 0;
		}
	| 	error	'\n'
		{ printf("? Redo from start.\n"); yyclearin; yyerrok; }
		line
		{ return 0; }
	;

expr	:	'(' expr ')'
                        { $$ = $2; }
	|	expr '^' expr
			{
			if (fndebug)
				printf("expr: expr ^ expr\n");
			new_code('^');
			}
	|	expr '*' expr	%prec '*'
			{
			if (fndebug)
				printf("expr: expr * expr\n");
			new_code('*');
			}
	|	expr '-' expr	%prec '-'
			{
			if (fndebug)
				printf("expr: expr - expr\n");
			new_code('-');
			}
	|	'-' expr 			%prec UMINUS
			{
			if (fndebug)
				printf("expr: '-' expr\t\t%d\n", $2);
			new_code(UMINUS);
			}
	|	SIN	expr
			{
			if (fndebug)
				printf("expr: func expr\t\t%d\n", $1);
			new_code($1);
			}
	|	INDEX
			{
			if (fndebug)
				printf("expr: INDEX\t\t%d\n", $1);
			new_code(- $1);  /* operand are negative values */
			}
	;
%%	/* programs */
static int sp2;

static int init_stack() { sp2=0; }

static int push2(double d)
{
  mem[sp2++] = d;
  if (sp2 >= MAXMEM) return 0;
  return 1;
}

static int pop2(double *d)
{
  if (sp2 <= 0) return 0;
  *d = mem[--sp2];
  return 1;
}

#include "lex.yy.c"

fnerr(int s)
{
fprintf(stderr, "class fn error: ");
switch(s)
  {
    case MALLOC: fprintf(stderr, "allocation error"); break;
    default: fprintf(stderr, "unknown error"); break;
  }
fprintf(stderr, ".\n");
}



FN *fnopen(void)
{
 FN *fnp; int i;


 memn=26; coden=0;

 Catstring[0] = '\0';
 fndebug = FNDEBUG;

 yyparse();

 fnp = (FN*) malloc(sizeof(FN));
 fnp->mem = (double*) malloc(memn*sizeof(double));
 if (!fnp->mem) fnerr(MALLOC);

 fnp->code = (int*)malloc(coden*sizeof(int));
 if (!fnp->code) fnerr(MALLOC);

 fnp->memn = memn;
 fnp->coden = coden;

 for (i=0; i<memn; i++) fnp->mem[i] = mem[i];
 for (i=0; i<coden; i++) fnp->code[i] = code[i];

 fnp->s = (char*)strdup((char*)Catstring);
 if (!fnp->s) fnerr(MALLOC);
 printf("fun=%s\n", fnp->s);

 return fnp;
}

double fnread(FN* f)
{
  va_list ap;
  char v[26];
  int nv=0;
  int i, op;
  double op1, op2;

  init_stack();

  if (fndebug>=2)
    {
      printf("coden=%d\n", f->coden);
      for (i=0; i<f->coden; i++)
        printf("%d ", f->code[i]);
      printf("\n");
    }


  for (i=0; i<f->coden; i++)
    if (f->code[i] < 0)
	{
	if (!push2(f->mem[ - f->code[i] ]) )
		fnerr(PUSH2);
	}
    else
       switch(f->code[i]) {
         case '+':
	   if(!pop2(&op2))
		fnerr(POP2);
	   if(!pop2(&op1))
		fnerr(POP2);
	   if(!push2(op1 + op2))
		fnerr(PUSH2);
	   break;

         case '-':
	   if(!pop2(&op2))
		fnerr(POP2);
	   if(!pop2(&op1))
		fnerr(POP2);
	   if(!push2(op1 - op2))
		fnerr(PUSH2);
	   break;

         case '/':
	   if(!pop2(&op2))
		fnerr(POP2);
	   if(!pop2(&op1))
		fnerr(POP2);
	   if (op2 == 0) fnerr(DIVBYZERO);
	   if(!push2(op1 / op2))
		fnerr(PUSH2);
	   break;

         case SIN:
	   if(!pop2(&op2))
		fnerr(POP2);
	   if(!push2(sin(op2)))
		fnerr(PUSH2);
	   break;

         case UMINUS:
	   if(!pop2(&op2))
		fnerr(POP2);
	   if(!push2(- op2))
		fnerr(PUSH2);
	   break;
	}

  if(!pop2(&op1))
	fnerr(POP2);
  return op1;
}
 
void fnclose(FN* fn)
{
  free(fn->mem), free(fn->code), free(fn->s);
  free(fn);
}

double *fnmemory(FN* f, int c)
{
  if (isalpha(c)) return & f->mem[toupper(c)-'A'];
  return NULL;
}

void fnsetmem(FN* f, int c, double d)
{
  if (isalpha(c)) 
    f->mem[toupper(c)-'A'] = d;
}
double fngetmem(FN* f, int c)
{
  if (isalpha(c)) 
    return f->mem[toupper(c)-'A'];
}

const char *fn(FN* f) { return f->s; }
/* eof fn.y */
