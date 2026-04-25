%{                          // SECTION 1 Declarations for C-Bison
#include <stdio.h>
#include <ctype.h>            // tolower()
#include <string.h>           // strcmp() 
#include <stdlib.h>           // exit()
#include <stdarg.h>           // variable argument formatting

#define FF fflush(stdout);    // to force immediate printing 

int yylex () ;
void yyerror (char *) ;
char *my_malloc (int) ;

// Not needed using Direct Translation:
char *gen_code (char *) ;
char *int_to_string (int) ;
char *char_to_string (char) ;
char *format_code (const char *, ...) ;
char *join_code (char *, char *) ;
char *fetch_ident (char *) ;
char *store_ident (char *, char *) ;
char *array_fetch (char *, char *) ;
char *array_store (char *, char *, char *) ;
char *params_to_locals (char *) ;
void add_scalar_decl (char *) ;
void add_array_decl (char *, int) ;
void set_current_params (char *) ;
void clear_current_params () ;
int is_current_param (char *) ;

char temp [4096] ;
char declarations [65536] = "" ;
char declared_names [1024][256] ;
int declared_kinds [1024] ;
int n_declared = 0 ;
char current_params [4096] = "" ;


// Definitions for explicit attributes

typedef struct s_attr {
    int value ;    // - Numeric value of a NUMBER 
    char *code ;   // - to pass IDENTIFIER names, and other translations 
} t_attr ;

#define YYSTYPE t_attr     // stack of PDA has type t_attr

char *format_code (const char *fmt, ...)
{
    va_list args ;
    int n ;
    char *p ;

    va_start (args, fmt) ;
    n = vsnprintf (NULL, 0, fmt, args) ;
    va_end (args) ;

    p = (char *) my_malloc (n + 1) ;

    va_start (args, fmt) ;
    vsnprintf (p, n + 1, fmt, args) ;
    va_end (args) ;

    return p ;
}

char *join_code (char *a, char *b)
{
    int len_a = (a == NULL) ? 0 : strlen (a) ;
    int len_b = (b == NULL) ? 0 : strlen (b) ;
    char *p ;

    if (len_a == 0 && len_b == 0)
        return gen_code ("") ;
    if (len_a == 0)
        return gen_code (b) ;
    if (len_b == 0)
        return gen_code (a) ;

    p = (char *) my_malloc (len_a + len_b + 2) ;
    sprintf (p, "%s\n%s", a, b) ;
    return p ;
}

int find_decl (char *name)
{
    int i ;

    for (i = 0; i < n_declared; i++) {
        if (strcmp (declared_names [i], name) == 0)
            return i ;
    }

    return -1 ;
}

void add_decl_line (char *line)
{
    if (strlen (declarations) > 0)
        strcat (declarations, "\n") ;
    strcat (declarations, line) ;
}

void add_scalar_decl (char *name)
{
    int pos ;

    pos = find_decl (name) ;
    if (pos >= 0)
        return ;

    strcpy (declared_names [n_declared], name) ;
    declared_kinds [n_declared++] = 1 ;
    sprintf (temp, "variable %s", name) ;
    add_decl_line (temp) ;
}

void add_array_decl (char *name, int size)
{
    int pos ;

    pos = find_decl (name) ;
    if (pos >= 0)
        return ;

    strcpy (declared_names [n_declared], name) ;
    declared_kinds [n_declared++] = 2 ;
    sprintf (temp, "create %s %d cells allot", name, size) ;
    add_decl_line (temp) ;
}

int name_in_list (char *list, char *name)
{
    char item [256] ;
    int i = 0 ;
    int j ;

    while (list [i] != '\0') {
        while (list [i] == ' ')
            i++ ;
        if (list [i] == '\0')
            break ;

        j = 0 ;
        while (list [i] != '\0' && list [i] != ' ' && j < 255)
            item [j++] = list [i++] ;
        item [j] = '\0' ;

        if (strcmp (item, name) == 0)
            return 1 ;
    }

    return 0 ;
}

void set_current_params (char *params)
{
    if (params == NULL)
        current_params [0] = '\0' ;
    else {
        strncpy (current_params, params, sizeof (current_params) - 1) ;
        current_params [sizeof (current_params) - 1] = '\0' ;
    }
}

void clear_current_params ()
{
    current_params [0] = '\0' ;
}

int is_current_param (char *name)
{
    return name_in_list (current_params, name) ;
}

char *fetch_ident (char *name)
{
    if (is_current_param (name))
        return gen_code (name) ;

    return format_code ("%s @", name) ;
}

char *store_ident (char *name, char *expr)
{
    if (is_current_param (name))
        return format_code ("%s to %s", expr, name) ;

    add_scalar_decl (name) ;
    return format_code ("%s %s !", expr, name) ;
}

char *array_fetch (char *name, char *index)
{
    return format_code ("%s %s cells + @", name, index) ;
}

char *array_store (char *name, char *index, char *expr)
{
    return format_code ("%s\n%s %s cells + !", expr, name, index) ;
}

char *params_to_locals (char *params)
{
    if (params == NULL || strlen (params) == 0)
        return gen_code ("") ;

    return format_code ("{ %s -- }", params) ;
}

%}

// Definitions for explicit attributes

%token NUMBER        
%token IDENTIF       // Identifier=variable
%token STRING        // token for string type
%token MAIN          // token for keyword main // main is not predefined in Lisp but we will use it as a keyword0+
%token WHILE         // token for keyword while
%token LOOP
%token DO
%token SETQ
%token SETF 
%token DEFUN     
%token PRINT  
%token PRINC
%token AREF
%token MAKE_ARRAY
%token RETURN_FROM
%token AND
%token IF 
%token PROGN
%token OR EQ NEQ GEQ LEQ MOD NOT


// %prec section not needed in LISP


%%                            // Section 3 Grammar - Semantic Actions
axiom:        exprSeq
                {
                    if (strlen (declarations) > 0)
                        printf ("%s\n", declarations) ;
                    printf ("%s\n", $1.code) ;
                }
            ;


exprSeq:      expression1 exprSeq               { $$.code = join_code ($1.code, $2.code) ; }
            | /* lambda */                      { $$.code = gen_code ("") ; }
            ;


expression1:  expression                        { $$ = $1 ; }

            | '(' SETQ IDENTIF number ')'       {
                                                    add_scalar_decl ($3.code) ;
                                                    $$.code = format_code ("%s %s !", $4.code, $3.code) ;
                                                }

            | '(' SETQ IDENTIF '(' MAKE_ARRAY number ')' ')' {
                                                    add_array_decl ($3.code, $6.value) ;
                                                    $$.code = gen_code ("") ;
                                                }

            | '(' SETF IDENTIF expression ')'   { $$.code = store_ident ($3.code, $4.code) ; }

            | '(' SETF '(' AREF IDENTIF expression ')' expression ')' {
                                                    $$.code = array_store ($5.code, $6.code, $8.code) ;
                                                }

            | '(' PRINT STRING ')'              { $$.code = format_code (".\" %s\" cr", $3.code) ; }

            | '(' PRINC expression ')'          { $$.code = format_code ("%s\n.", $3.code) ; }
            | '(' PRINC STRING ')'              { $$.code = format_code (".\" %s\"", $3.code) ; }

            | '(' PROGN exprSeq ')'             { $$ = $3 ; }

            | '(' MAIN ')'                      { $$.code = gen_code ("main") ; }

            | '(' RETURN_FROM IDENTIF expression ')' {
                                                    $$.code = format_code ("%s\nexit", $4.code) ;
                                                }

            | '(' DEFUN MAIN '(' ')'            { clear_current_params () ; }
                exprSeq ')'                     {
                                                    $$.code = format_code (": main recursive\n%s\n;", $7.code) ;
                                                    clear_current_params () ;
                                                }

            | '(' DEFUN IDENTIF '(' parametros ')' {
                                                    set_current_params ($5.code) ;
                                                }
                exprSeq ')'                     {
                                                    $$.code = format_code (": %s recursive %s\n%s\n;",
                                                                           $3.code, params_to_locals ($5.code), $8.code) ;
                                                    clear_current_params () ;
                                                }

            | '(' LOOP WHILE expression DO exprSeq ')' {
                                                    $$.code = format_code ("begin\n%s\nwhile\n%s\nrepeat", $4.code, $6.code) ;
                                                }

            | '(' ifHead expression1 ')'        { $$.code = format_code ("%s\n%s\nthen", $2.code, $3.code) ; }

            | '(' ifHead expression1 expression1 ')' {
                                                    $$.code = format_code ("%s\n%s\nelse\n%s\nthen",
                                                                           $2.code, $3.code, $4.code) ;
                                                }
            ;


ifHead:       IF expression                      { $$.code = format_code ("%s\nif", $2.code) ; }
            ;


parametros:   lista_parametros                  { $$ = $1 ; }
            | /* lambda */                      { $$.code = gen_code ("") ; }
            ;


lista_parametros:
              IDENTIF lista_parametros          {
                                                    if (strlen ($2.code) == 0)
                                                        $$.code = gen_code ($1.code) ;
                                                    else
                                                        $$.code = format_code ("%s %s", $1.code, $2.code) ;
                                                }
            | IDENTIF                           { $$.code = gen_code ($1.code) ; }
            ;


argumentos:   expression argumentos             { $$.code = join_code ($1.code, $2.code) ; }
            | /* lambda */                      { $$.code = gen_code ("") ; }
            ;


expression:   operand                           { $$ = $1 ; }
            | '(' '+' expression expression ')' { $$.code = format_code ("%s\n%s\n+", $3.code, $4.code) ; }
            | '(' '-' expression expression ')' { $$.code = format_code ("%s\n%s\n-", $3.code, $4.code) ; }
            | '(' '*' expression expression ')' { $$.code = format_code ("%s\n%s\n*", $3.code, $4.code) ; }
            | '(' '/' expression expression ')' { $$.code = format_code ("%s\n%s\n/", $3.code, $4.code) ; }
            | '(' MOD expression expression ')' { $$.code = format_code ("%s\n%s\nmod", $3.code, $4.code) ; }
            | '(' AND expression expression ')' { $$.code = format_code ("%s\n%s\nand", $3.code, $4.code) ; }
            | '(' OR expression expression ')'  { $$.code = format_code ("%s\n%s\nor", $3.code, $4.code) ; }
            | '(' '=' expression expression ')' { $$.code = format_code ("%s\n%s\n=", $3.code, $4.code) ; }
            | '(' NEQ expression expression ')' { $$.code = format_code ("%s\n%s\n=\n0=", $3.code, $4.code) ; }
            | '(' '<' expression expression ')' { $$.code = format_code ("%s\n%s\n<", $3.code, $4.code) ; }
            | '(' LEQ expression expression ')' { $$.code = format_code ("%s\n%s\n<=", $3.code, $4.code) ; }
            | '(' '>' expression expression ')' { $$.code = format_code ("%s\n%s\n>", $3.code, $4.code) ; }
            | '(' GEQ expression expression ')' { $$.code = format_code ("%s\n%s\n>=", $3.code, $4.code) ; }
            | '(' NOT expression ')'            { $$.code = format_code ("%s\n0=", $3.code) ; }
            | '(' '-' expression ')'            { $$.code = format_code ("%s\nnegate", $3.code) ; }
            | '(' AREF IDENTIF expression ')'   { $$.code = array_fetch ($3.code, $4.code) ; }
            | '(' IDENTIF argumentos ')'        {
                                                    if (strlen ($3.code) == 0)
                                                        $$.code = gen_code ($2.code) ;
                                                    else
                                                        $$.code = format_code ("%s\n%s", $3.code, $2.code) ;
                                                }
            ;


operand:      IDENTIF                           { $$.code = fetch_ident ($1.code) ; }
            | number                            { $$ = $1 ; }
            ;


number:       NUMBER                            {
                                                    $$.value = $1.value ;
                                                    $$.code = format_code ("%d", $1.value) ;
                                                }
            | '-' NUMBER                        {
                                                    $$.value = -$2.value ;
                                                    $$.code = format_code ("%d", -$2.value) ;
                                                }
            ;


%%                            // SECTION 4    Code in C

int n_line = 1 ;

void yyerror (char *message)
{
    fprintf (stderr, "%s in line %d\n", message, n_line) ;
    printf ( "\n") ;
}

char *int_to_string (int n)
{
    char temp [1024] ;

    sprintf (temp, "%d", n) ;

    return gen_code (temp) ;
}

char *char_to_string (char c)
{
    char temp [1024] ;

    sprintf (temp, "%c", c) ;

    return gen_code (temp) ;
}

char *gen_code (char *name)   // copy the argument to an  
{                             // string in dynamic memory  
    char *p ;
    int l ;
	
    l = strlen (name)+1 ;
    p = (char *) my_malloc (l) ;
    strcpy (p, name) ;
	
    return p ;
}

char *my_malloc (int nbytes)     // reserve n bytes of dynamic memory 
{
    char *p ;
    static long int nb = 0 ;     // used to count the memory  
    static int nv = 0 ;          // required in total 

    p = malloc (nbytes) ;
    if (p == NULL) {
      fprintf (stderr, "No memory left for additional %d bytes\n", nbytes) ;
      fprintf (stderr, "%ld bytes reserved in %d calls \n", nb, nv) ;  
      exit (0) ;
    }
    nb += (long) nbytes ;
    nv++ ;

    return p ;
}



/***************************************************************************/
/***************************** Keyword Section *****************************/
/***************************************************************************/

typedef struct s_keyword { // for the reserved words of C  
    char *name ;
    int token ;
} t_keyword ;

t_keyword keywords [] = {     // define the keywords 
    "main",        MAIN,      // and their associated token  
    "defun",       DEFUN,
    "print",       PRINT,
    "princ",       PRINC,
    "aref",        AREF,
    "make-array",  MAKE_ARRAY,
    "return-from", RETURN_FROM,
    "loop",        LOOP,
    "while",       WHILE,
    "do",          DO,
    "and",         AND,
    "if",          IF,
    "progn",       PROGN,
    "setq",        SETQ,
    "setf",        SETF,
    "or",          OR,
    "=",           EQ,
    "/=",          NEQ,
    "<=",          LEQ,
    ">=",          GEQ,
    "mod",         MOD,
    "not",         NOT,
    NULL,          0          // 0 to mark the end of the table
} ;

t_keyword *search_keyword (char *symbol_name)
{                       // Search symbol names in the keyword table
                        // and return a pointer to token register
    int i ;
    t_keyword *sim ;

    i = 0 ;
    sim = keywords ;
    while (sim [i].name != NULL) {
	    if (strcmp (sim [i].name, symbol_name) == 0) {
                                   // strcmp(a, b) returns == 0 if a==b  
            return &(sim [i]) ;
        }
        i++ ;
    }

    return NULL ;
}

 
/***************************************************************************/
/******************** Section for the Lexical Analyzer  ********************/
/***************************************************************************/

int yylex ()
{
    int i ;
    unsigned char c ;
    unsigned char cc ;
    char expandable_ops [] =  "!<>=|%&/-*+" ;
    char temp_str [256] ;
    t_keyword *symbol ;

    do { 
        c = getchar () ; 
        if (c == '#') { // Ignore the lines starting with # (#define, #include) 
            do { // WARNING that it may malfunction if a line contains # 
                c = getchar () ; 
            } while (c != '\n') ; 
        } 
        if (c == '/') { // character / can be the beginning of a comment. 
            cc = getchar () ; 
            if (cc != '/') { // If the following char is / is a comment, but.... 
                ungetc (cc, stdin) ; 
            } else { 
                c = getchar () ; // ... 
                if (c == '@') { // Lines starting with //@ are transcribed
                    do { // This is inline code (embedded code in C).
                        c = getchar () ; 
                        putchar (c) ; 
                    } while (c != '\n' && c != EOF) ;
                    if (c == EOF) {
                        ungetc (c, stdin) ;
                    } 
                } else { // ==> comment, ignore the line 
                    while (c != '\n') { 
                        c = getchar () ; 
                    } 
                } 
            } 
        } 
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
            printf ("WARNING: string with more than 255 characters in line %d\n", n_line) ; 
        } // we should read until the next “, but, what if it is  missing? 
        temp_str [--i] = '\0' ;
        yylval.code = gen_code (temp_str) ;
        return (STRING) ;
    }

    if (c == '.' || (c >= '0' && c <= '9')) {
        ungetc (c, stdin) ;
        scanf ("%d", &yylval.value) ;
//         printf ("\nDEV: NUMBER %d\n", yylval.value) ;       
        return NUMBER ;
    }

    if ((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
        i = 0 ;
        while (((c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') ||
            (c >= '0' && c <= '9') || c == '_' || c == '-') && i < 255) {
        temp_str [i++] = tolower (c) ; // ALL TO SMALL LETTERS
        c = getchar () ; 
    } 
    temp_str [i] = '\0' ; // End of string  
    ungetc (c, stdin) ; // return excess char  

    yylval.code = gen_code (temp_str) ; 
    symbol = search_keyword (yylval.code) ;
    if (symbol == NULL) { // is not reserved word -> iderntifrier  
//               printf ("\nDEV: IDENTIF %s\n", yylval.code) ;    // PARA DEPURAR
            return (IDENTIF) ;
        } else {
//               printf ("\nDEV: OTRO %s\n", yylval.code) ;       // PARA DEPURAR
            return (symbol->token) ;
        }
    }

    if (strchr (expandable_ops, c) != NULL) { // // look for c in expandable_ops
        cc = getchar () ;
        sprintf (temp_str, "%c%c", (char) c, (char) cc) ;
        symbol = search_keyword (temp_str) ;
        if (symbol == NULL) {
            ungetc (cc, stdin) ;
            yylval.code = NULL ;
            return (c) ;
        } else {
            yylval.code = gen_code (temp_str) ; // although it is not used
            return (symbol->token) ;
        }
    }

//    printf ("\nDEV: LITERAL %d #%c#\n", (int) c, c) ;      // PARA DEPURAR
    if (c == EOF || c == 255 || c == 26) {
//         printf ("tEOF ") ;                                // PARA DEPURAR
        return (0) ;
    }

    return c ;
}


int main ()
{
    return yyparse () ;
}
