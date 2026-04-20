/* 117, Tristán Serrano Álvarez, Mario Agúndez Díaz
   100522148@alumnos.uc3m.es, 100522312@alumnos.uc3m.es
 */

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
char *combina_codigos (char *, char *) ;
char *string_a_lisp (char *) ;
void append_codigo (char *, char *) ;

char temp [4096] ; // Ampliado un poco para concatenaciones largas
char *locales[256];
int n_locales = 0;
char *prefijo = "";
char *funcion_actual = "";

void borrar_loc_vars() { n_locales = 0; }
void add_loc_var(char *name) { locales[n_locales++] = gen_code(name); }
int es_local(char *name) {
    for (int i = 0; i < n_locales; i++)
        if (strcmp(locales[i], name) == 0) return 1;
    return 0;
}

void append_codigo (char *dest, char *code)
{
    if (code == NULL || strlen (code) == 0)
        return ;

    if (strlen (dest) > 0)
        strcat (dest, "\n") ;

    strcat (dest, code) ;
}

char *combina_codigos (char *a, char *b)
{
    temp[0] = '\0' ;
    append_codigo (temp, a) ;
    append_codigo (temp, b) ;
    return gen_code (temp) ;
}

char *string_a_lisp (char *raw)
{
    char local [4096] ;
    int i, j ;

    j = 0 ;
    local [j++] = '\"' ;
    for (i = 0; raw [i] != '\0' && j < 4093; i++) {
        if (raw [i] == '\"' || raw [i] == '\\')
            local [j++] = '\\' ;
        local [j++] = raw [i] ;
    }
    local [j++] = '\"' ;
    local [j] = '\0' ;

    return gen_code (local) ;
}


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
%token FOR INC DEC
%token PUTS
%token PRINTF
%token IF      
%token ELSE
%token AND OR EQ NEQ GEQ LEQ
%token SWITCH CASE DEFAULT BREAK
%token RETURN


%right '='                    
%left OR                      
%left AND                    
%left EQ NEQ              
%left '<' '>' LEQ GEQ        
%left '+' '-'                 
%left '*' '/' '%'             
%right '!' SIGNO_UNARIO           

%%


programa:       
    lista_declaraciones lista_funciones funcion_main { printf ("%s\n%s\n%s\n", $1.code, $2.code, $3.code) ; }
    ;


lista_declaraciones:
    declaracion lista_declaraciones { $$.code = combina_codigos ($1.code, $2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

declaracion:
    INTEGER lista_variables ';' { $$ = $2 ; }
    ;

lista_variables:
    variable { $$ = $1 ; }
    | variable ',' lista_variables { $$.code = combina_codigos ($1.code, $3.code) ; }
    ;

variable:
    VARIABLE { sprintf (temp, "(setq %s 0)", $1.code) ; 
                $$.code = gen_code (temp) ; }
    | VARIABLE '=' NUMERO { sprintf (temp, "(setq %s %d)", $1.code, $3.value) ; 
                            $$.code = gen_code (temp) ; }
    | VARIABLE '[' NUMERO ']' { sprintf (temp, "(setq %s (make-array %d))", $1.code, $3.value) ;
                                $$.code = gen_code (temp) ; }
    ;


lista_funciones:
    funcion lista_funciones { $$.code = combina_codigos ($1.code, $2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

funcion_main:
    MAIN '(' ')' '{' { prefijo = "main"; funcion_actual = "main"; borrar_loc_vars(); } 
    lista_declaraciones_locales lista_sentencias '}' {
                                            sprintf (temp, "(defun main ()") ;
                                            if (strlen ($6.code) > 0) {
                                                append_codigo (temp, $6.code) ;
                                            }
                                            if (strlen ($7.code) > 0) {
                                                append_codigo (temp, $7.code) ;
                                            }
                                            sprintf (temp + strlen (temp), "\n)\n\n(main)") ;
                                            $$.code = gen_code (temp) ; }
    ;

funcion:
    VARIABLE '(' parametros_def ')' '{' { prefijo = $1.code; funcion_actual = $1.code; borrar_loc_vars(); }
    lista_declaraciones_locales lista_sentencias_funcion retorno_final '}' {
        sprintf (temp, "(defun %s (%s)", $1.code, $3.code) ;
        if (strlen ($7.code) > 0) {
            append_codigo (temp, $7.code) ;
        }
        if (strlen ($8.code) > 0) {
            append_codigo (temp, $8.code) ;
        }
        if (strlen ($9.code) > 0) {
            append_codigo (temp, $9.code) ;
        }
        sprintf (temp + strlen (temp), "\n)\n") ;
        $$.code = gen_code (temp) ;
    }
    ;

parametros_def:
    lista_parametros_def { $$ = $1 ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

lista_parametros_def:
    parametro_def { $$ = $1 ; }
    | parametro_def ',' lista_parametros_def { sprintf (temp, "%s %s", $1.code, $3.code) ;
                                               $$.code = gen_code (temp) ; }
    ;

parametro_def:
    INTEGER VARIABLE { $$.code = gen_code ($2.code) ; }
    ;

lista_declaraciones_locales:
    declaracion_local lista_declaraciones_locales { $$.code = combina_codigos ($1.code, $2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

declaracion_local:
    INTEGER lista_variables_locales ';' { $$ = $2 ; }
    ;

lista_variables_locales:
    variable_local { $$ = $1 ; }
    | variable_local ',' lista_variables_locales { $$.code = combina_codigos ($1.code, $3.code) ; }
    ;

variable_local:
    VARIABLE { add_loc_var($1.code);
                sprintf (temp, "(setq %s_%s 0)", prefijo, $1.code) ; 
                $$.code = gen_code (temp) ; }
    | VARIABLE '=' NUMERO { add_loc_var($1.code);
                                sprintf (temp, "(setq %s_%s %d)", prefijo, $1.code, $3.value) ;
                                $$.code = gen_code (temp) ; }
    | VARIABLE '[' NUMERO ']' { add_loc_var($1.code);
                                sprintf (temp, "(setq %s_%s (make-array %d))", prefijo, $1.code, $3.value) ;
                                $$.code = gen_code (temp) ; }
    ;

lista_sentencias:
    sentencia lista_sentencias { $$.code = combina_codigos ($1.code, $2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

lista_sentencias_funcion:
    sentencia_no_retorno lista_sentencias_funcion { $$.code = combina_codigos ($1.code, $2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;


sentencia:
    sentencia_no_retorno { $$ = $1 ; }
    | RETURN expresion ';' { sprintf (temp, "(return-from %s %s)", funcion_actual, $2.code) ;
                             $$.code = gen_code (temp) ; }
    ;

sentencia_no_retorno:    
    VARIABLE '=' expresion ';' { if (es_local($1.code))
                                    sprintf (temp, "(setf %s_%s %s)", prefijo, $1.code, $3.code) ; 
                                else
                                    sprintf (temp, "(setf %s %s)", $1.code, $3.code) ; 
                                $$.code = gen_code (temp) ;}
    | VARIABLE '[' expresion ']' '=' expresion ';' {
                                if (es_local($1.code))
                                    sprintf (temp, "(setf (aref %s_%s %s) %s)", prefijo, $1.code, $3.code, $6.code) ;
                                else
                                    sprintf (temp, "(setf (aref %s %s) %s)", $1.code, $3.code, $6.code) ;
                                $$.code = gen_code (temp) ;}
    | llamada_funcion ';' { $$ = $1 ; }
    | PUTS '(' STRING ')' ';' { sprintf (temp, "(print %s)", string_a_lisp ($3.code)) ;
                                $$.code = gen_code (temp) ; }
    | PRINTF '(' STRING ',' lista_printf ')' ';' { $$ = $5 ; }
    | WHILE '(' expresion ')' '{' lista_sentencias '}' { sprintf (temp, "(loop while %s do\n%s)", $3.code, $6.code) ; 
                                                            $$.code = gen_code (temp) ; }
    | IF '(' expresion ')' '{' lista_sentencias '}' {sprintf (temp, "(if %s\n(progn\n%s))", $3.code, $6.code) ;
                                                      $$.code = gen_code (temp) ;}
    | IF '(' expresion ')' '{' lista_sentencias '}' ELSE '{' lista_sentencias '}' {
                                                                sprintf (temp, "(if %s\n(progn\n%s)\n(progn\n%s))", $3.code, $6.code, $10.code) ;
                                                                $$.code = gen_code (temp) ;}
    | FOR '(' VARIABLE '=' expresion ';' expresion ';' INC '(' VARIABLE ')' ')' '{' lista_sentencias '}' 
                        { char v_init[256], v_mod[256];
                        if (strcmp($3.code, $11.code) != 0) {
                            yyerror("INC debe aplicarse a la misma variable indice del for");
                            YYERROR;
                        }
                        if (es_local($3.code)) sprintf(v_init, "%s_%s", prefijo, $3.code);
                        else sprintf(v_init, "%s", $3.code);

                        if (es_local($11.code)) sprintf(v_mod, "%s_%s", prefijo, $11.code);
                        else sprintf(v_mod, "%s", $11.code);

                        sprintf(temp, "(setf %s %s)\n(loop while %s do\n%s\n(setf %s (+ %s 1)))", 
                                v_init, $5.code, $7.code, $15.code, v_mod, v_mod);
                        $$.code = gen_code(temp);}
    | FOR '(' VARIABLE '=' expresion ';' expresion ';' DEC '(' VARIABLE ')' ')' '{' lista_sentencias '}' 
                        { char v_init[256], v_mod[256];
                        if (strcmp($3.code, $11.code) != 0) {
                            yyerror("DEC debe aplicarse a la misma variable indice del for");
                            YYERROR;
                        }
        
                        if (es_local($3.code)) sprintf(v_init, "%s_%s", prefijo, $3.code);
                        else sprintf(v_init, "%s", $3.code);

                        if (es_local($11.code)) sprintf(v_mod, "%s_%s", prefijo, $11.code);
                        else sprintf(v_mod, "%s", $11.code);

                        sprintf(temp, "(setf %s %s)\n(loop while %s do\n%s\n(setf %s (- %s 1)))", 
                                v_init, $5.code, $7.code, $15.code, v_mod, v_mod);
                        $$.code = gen_code(temp);}
    | SWITCH '(' expresion ')' '{' lista_casos bloque_default '}' { sprintf (temp, "(case %s\n%s\n%s)", $3.code, $6.code, $7.code) ;
                                                                    $$.code = gen_code (temp) ; }
    ;

retorno_final:
    RETURN expresion ';' { $$.code = gen_code ($2.code) ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

lista_casos:
    caso lista_casos {
        $$.code = combina_codigos ($1.code, $2.code) ;
    }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

caso:
    CASE valor_case ':' lista_sentencias BREAK ';' {
        /* En Lisp, un caso es (valor expresiones...) */
        sprintf (temp, "(%d\n%s)", $2.value, $4.code) ;
        $$.code = gen_code (temp) ;
    }
    ;

valor_case:
    NUMERO { $$.value = $1.value ; }
    | '-' NUMERO %prec SIGNO_UNARIO { $$.value = -$2.value ; }
    ;

bloque_default:
    DEFAULT ':' lista_sentencias BREAK ';' {
        /* En Lisp, el caso por defecto se indica con 'otherwise' */
        sprintf (temp, "(otherwise\n%s)", $3.code) ;
        $$.code = gen_code (temp) ;
    }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

llamada_funcion:
    VARIABLE '(' argumentos ')' {
        if (strlen($3.code) == 0)
            sprintf (temp, "(%s)", $1.code) ;
        else
            sprintf (temp, "(%s %s)", $1.code, $3.code) ;
        $$.code = gen_code (temp) ;
    }
    ;

argumentos:
    lista_argumentos { $$ = $1 ; }
    | /* vacio */ { $$.code = gen_code ("") ; }
    ;

lista_argumentos:
    expresion { $$ = $1 ; }
    | expresion ',' lista_argumentos { sprintf (temp, "%s %s", $1.code, $3.code) ;
                                       $$.code = gen_code (temp) ; }
    ;

lista_printf:
    elemento_printf { sprintf (temp, "(princ %s)", $1.code) ;
                      $$.code = gen_code (temp) ; }
    | elemento_printf ',' lista_printf { sprintf (temp, "(princ %s)\n%s", $1.code, $3.code) ;
                                         $$.code = gen_code (temp) ; }
    ;

elemento_printf:
    expresion { $$ = $1 ; }
    | STRING { $$.code = string_a_lisp ($1.code) ; }
    ;

expresion:      
    termino                  { $$ = $1 ; }
    | expresion '+' expresion  { sprintf (temp, "(+ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '-' expresion  { sprintf (temp, "(- %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '*' expresion  { sprintf (temp, "(* %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '/' expresion  { sprintf (temp, "(/ %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '%' expresion  { sprintf (temp, "(mod %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion AND expresion  { sprintf (temp, "(and %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion OR expresion   { sprintf (temp, "(or %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion EQ expresion   { sprintf (temp, "(= %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion NEQ expresion  { sprintf (temp, "(/= %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '<' expresion  { sprintf (temp, "(< %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion LEQ expresion  { sprintf (temp, "(<= %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion '>' expresion  { sprintf (temp, "(> %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    | expresion GEQ expresion  { sprintf (temp, "(>= %s %s)", $1.code, $3.code) ; $$.code = gen_code (temp) ; }
    ;

termino:        
    operando                           { $$ = $1 ; }                          
    | '+' operando %prec SIGNO_UNARIO  { $$ = $2 ; }
    | '-' operando %prec SIGNO_UNARIO  { sprintf (temp, "(- %s)", $2.code) ; $$.code = gen_code (temp) ; }    
    | '!' operando %prec SIGNO_UNARIO  { sprintf (temp, "(not %s)", $2.code) ; $$.code = gen_code (temp) ; }
    ;
    
operando:       
    llamada_funcion           { $$ = $1 ; }
    | VARIABLE '[' expresion ']' {
                                if (es_local($1.code))
                                    sprintf (temp, "(aref %s_%s %s)", prefijo, $1.code, $3.code) ;
                                else
                                    sprintf (temp, "(aref %s %s)", $1.code, $3.code) ;
                                $$.code = gen_code (temp) ; }
    | VARIABLE                  { if (es_local($1.code))
                                    sprintf (temp, "%s_%s", prefijo, $1.code) ;
                                else
                                    sprintf (temp, "%s", $1.code) ;
                                $$.code = gen_code (temp) ;}
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
    { "main",        MAIN },
    { "int",         INTEGER },
    { "puts",        PUTS },
    { "printf",      PRINTF },
    { "if",          IF },
    { "else",        ELSE },
    { "while",       WHILE },
    { "&&",          AND },
    { "||",          OR },
    { "==",          EQ },
    { "!=",          NEQ },
    { "<=",          LEQ },
    { ">=",          GEQ },
    { "for",         FOR },
    { "inc",         INC },
    { "dec",         DEC },
    { "switch",      SWITCH },
    { "case",        CASE },
    { "default",     DEFAULT },
    { "break",       BREAK },
    { "return",      RETURN },
    { NULL,          0 }
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
    int c ;
    int cc ;
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
        while (i < 255) {
            c = getchar () ;
            if (c == '\\') {
                cc = getchar () ;
                if (cc == 'n') {
                    temp_str [i++] = '\n' ;
                } else if (cc == '\"') {
                    temp_str [i++] = '\"' ;
                } else if (cc == '\\') {
                    temp_str [i++] = '\\' ;
                } else {
                    temp_str [i++] = '\\' ;
                    if (i < 255)
                        temp_str [i++] = cc ;
                }
            } else if (c == '\"') {
                break ;
            } else {
                temp_str [i++] = c ;
            }
        }
        if (i == 256) {
            printf ("AVISO: string con mas de 255 caracteres en linea %d\n", n_line) ;
        }		 	
        temp_str [i] = '\0' ;
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
