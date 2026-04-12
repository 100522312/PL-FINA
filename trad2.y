%{
#include <stdio.h>
#include <ctype.h>            
#include <string.h>           
#include <stdlib.h>           

#define FF fflush(stdout);

int yylex () ;
int yyerror (char *mensaje) ;
char *my_malloc (int) ;
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;

char temp [4096] ; // Ampliado un poco para concatenaciones largas

typedef struct ASTnode t_node ;
struct ASTnode {
    char *op ;
    int type ;
    t_node *left ;
    t_node *right ;
} ;

typedef struct s_attr {
    int value ;
    char *code ;
    t_node *node ;
} t_attr ;

#define YYSTYPE t_attr
%}

%token NUMERO        
%token VARIABLE       
%token INTEGER       
%token STRING
%token MAIN          
%token WHILE         
%token PUTS
%token PRINTF

%right '='                    
%left '+' '-'                 
%left '*' '/'                 
%left SIGNO_UNARIO          

%%


programa:       
    lista_declaraciones funcion_main { printf ("%s\n%s\n", $1.code, $2.code) ; }
    ;


lista_declaraciones:
    declaracion lista_declaraciones { sprintf (temp, "%s\n%s", $1.code, $2.code) ; 
                                        $$.code = gen_code (temp) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

declaracion:
    INTEGER lista_variables ';' { $$ = $2 ; }
    ;

lista_variables:
    variable { $$ = $1 ; }
    | variable ',' lista_variables { sprintf (temp, "%s\n%s", $1.code, $3.code) ; 
                                        $$.code = gen_code (temp) ; }
    ;

variable:
    VARIABLE { sprintf (temp, "(setq %s 0)", $1.code) ; 
                $$.code = gen_code (temp) ; }
    | VARIABLE '=' NUMERO { sprintf (temp, "(setq %s %d)", $1.code, $3.value) ; 
                            $$.code = gen_code (temp) ; }
    ;


funcion_main:
    MAIN '(' ')' '{' lista_sentencias '}' { sprintf (temp, "(defun main ()\n%s)\n\n(main)", $5.code) ; 
                                            $$.code = gen_code (temp) ; }
    ;

lista_sentencias:
    sentencia lista_sentencias { 
        sprintf (temp, "%s\n%s", $1.code, $2.code) ; 
        $$.code = gen_code (temp) ; 
    }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;


sentencia:    
    VARIABLE '=' expresion ';' { sprintf (temp, "(setq %s %s)", $1.code, $3.code) ; 
                                $$.code = gen_code (temp) ; }
    | PUTS '(' STRING ')' ';' { sprintf (temp, "(print \"%s\")", $3.code) ;
                                $$.code = gen_code (temp) ; }
    | PRINTF '(' STRING ',' lista_printf ')' ';' { $$ = $5 ; }
    ;

lista_printf:
    elemento_printf { sprintf (temp, "(princ %s)", $1.code) ;
                      $$.code = gen_code (temp) ; }
    | elemento_printf ',' lista_printf { sprintf (temp, "(princ %s)\n%s", $1.code, $3.code) ;
                                         $$.code = gen_code (temp) ; }
    ;

elemento_printf:
    expresion { $$ = $1 ; }
    | STRING { sprintf (temp, "\"%s\"", $1.code) ;
               $$.code = gen_code (temp) ; }
    ;

expresion:      
    termino                  { $$ = $1 ; }
    | expresion '+' expresion  { sprintf (temp, "(+ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '-' expresion  { sprintf (temp, "(- %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '*' expresion  { sprintf (temp, "(* %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '/' expresion  { sprintf (temp, "(/ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    ;

termino:        
    operando                           { $$ = $1 ; }                          
    | '+' operando %prec SIGNO_UNARIO      { $$ = $2 ; }
    | '-' operando %prec SIGNO_UNARIO      { sprintf (temp, "(- %s)", $2.code) ; $$.code = gen_code (temp) ; }    
    ;

operando:       
    VARIABLE                  { sprintf (temp, "%s", $1.code) ; $$.code = gen_code (temp) ; }
    | NUMERO                   { sprintf (temp, "%d", $1.value) ; $$.code = gen_code (temp) ; }
    | '(' expresion ')'        { $$ = $2 ; }
    ;

%%


int n_line = 1 ;

int yyerror (char *mensaje)
{
    fprintf (stderr, "%s en la linea %d\n", mensaje, n_line) ;
    printf ( "\n") ;	// bye
    return 0 ;
}

char *int_to_string (int n)
{
    char ltemp [2048] ;
    sprintf (ltemp, "%d", n) ;
    return gen_code (ltemp) ;
}

char *char_to_string (char c)
{
    char ltemp [2048] ;
    sprintf (ltemp, "%c", c) ;
    return gen_code (ltemp) ;
}

char *my_malloc (int nbytes)
{
    char *p ;
    static long int nb = 0;
    static int nv = 0 ;

    p = malloc (nbytes) ;
    if (p == NULL) {
        fprintf (stderr, "No queda memoria para %d bytes mas\n", nbytes) ;
        fprintf (stderr, "Reservados %ld bytes en %d llamadas\n", nb, nv) ;
        exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;
    return p ;
}

typedef struct s_keyword { 
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = { 
    "main",        MAIN,           
    "int",         INTEGER,
    "puts",        PUTS,
    "printf",      PRINTF,
    NULL,          0               
} ;

t_keyword *search_keyword (char *symbol_name)
{                                  
    int i = 0 ;
    t_keyword *sim = keywords ;
    while (sim [i].name != NULL) {
	    if (strcmp (sim [i].name, symbol_name) == 0) {
            return &(sim [i]) ;
        }
        i++ ;
    }
    return NULL ;
}

char *gen_code (char *name)     
{                                      
    char *p ;
    int l ;
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
    return p ;
}

int yylex ()
{
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char ops_expandibles [] = "!<=|>%&/+-*" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do {
        c = getchar () ;
        if (c == '#') {	
            do {		
                c = getchar () ;
            } while (c != '\n') ;
        }

        if (c == '/') {	
            cc = getchar () ;
            if (cc != '/') {   
                ungetc (cc, stdin) ;
            } else {
                c = getchar () ;
                if (c == '@') {	
                    do {		
                        c = getchar () ;
                        putchar (c) ;
                    } while (c != '\n') ;
                } else {		
                    while (c != '\n') {
                        c = getchar () ;
                    }
                }
            }
        } else if (c == '\\') c = getchar () ;
        if (c == '\n')
            n_line++ ;
    } while (c == ' ' || c == '\n' || c == 10 || c == 13 || c == '\t') ;

    if (c == '\"') {
        i = 0 ;
        do {
            c = getchar () ;
            temp_str [i++] = c ;
        } while (c != '\"' && i < 255) ;
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }		 	
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
        return NUMERO ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_') && i < 255) {
            temp_str [i++] = tolower (c) ;
            c = getchar () ;
        }
        temp_str [i] = '\0' ;
        ungetc (c, stdin) ;

        yylval.code = gen_code (temp_str) ;
        symbol = search_keyword (yylval.code) ;
   
        if (symbol == NULL) {    
            return (VARIABLE) ;
        } else {
            return (symbol->token) ;
        }
    }

    if (strchr (ops_expandibles, c) != NULL) { 
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ;
            return (symbol->token) ;
        }
    }

    if (c == EOF || c == 255 || c == 26) {
        return (0) ;
    }

    return c ;
}

int main ()
{
    yyparse () ;
    return 0 ;
}
