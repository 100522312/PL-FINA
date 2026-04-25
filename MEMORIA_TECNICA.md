# Memoria tecnica del proyecto

## Traductor de subconjunto de C a Lisp y de Lisp a notacion postfija/Forth

**Autores:** Tristan Serrano Alvarez y Mario Agundez Diaz  
**Grupo:** 117  
**Correos:** 100522148@alumnos.uc3m.es, 100522312@alumnos.uc3m.es

---

## 1. Introduccion

El objetivo del proyecto es implementar un traductor para un subconjunto del lenguaje C utilizando Bison y acciones semanticas. El trabajo se ha desarrollado de forma incremental a partir del codigo inicial proporcionado en la asignatura, extendiendo primero el frontend de C a Lisp y completando despues un backend capaz de traducir ese Lisp intermedio a una notacion postfija ejecutable por `gforth`.

La estructura final del proyecto queda dividida en dos etapas:

```text
Programa C
   |
   v
trad3
   |
   v
Codigo intermedio Lisp
   |
   v
back3
   |
   v
Codigo Forth / notacion postfija
   |
   v
gforth
```

La idea principal es separar la traduccion en dos problemas mas simples. El frontend se encarga de reconocer el subconjunto de C y expresarlo en una representacion Lisp uniforme. El backend recibe esa representacion, ya mucho mas regular, y la convierte en codigo de pila para Forth.

---

## 2. Objetivos del proyecto

Los objetivos tecnicos principales son:

- Reconocer un subconjunto representativo de C mediante un analizador lexico y sintactico implementado con Bison.
- Traducir construcciones de C a una representacion intermedia en Lisp.
- Mantener la semantica basica de expresiones, variables, control de flujo, funciones, llamadas, retornos y vectores.
- Implementar un backend que traduzca el Lisp generado a codigo Forth/postfijo.
- Ejecutar el resultado final mediante `gforth`.
- Validar el comportamiento con los programas de prueba de `tests-2026`.

La ejecucion esperada del proyecto es:

```bash
cat prueba.c | ./trad3 | ./back3 | gforth
```

Tambien se puede inspeccionar cada fase por separado:

```bash
./trad3 < prueba.c > prueba.l
./back3 < prueba.l > prueba.fs
gforth prueba.fs
```

---

## 3. Evolucion del trabajo

### 3.1 Primera ampliacion: `trad2.y`

En la segunda fase del proyecto se partio del fichero inicial `trad1e.y` y se amplio el traductor para obtener `trad2.y`. El objetivo era pasar de un traductor de expresiones simples a uno capaz de procesar pequenos programas en C.

En esta fase se incorporaron:

- Declaraciones globales de variables `int`.
- Inicializacion de variables con constantes.
- Funcion principal `main`.
- Asignaciones.
- Traduccion de `puts`.
- Traduccion de `printf`, ignorando la cadena de formato y generando una llamada `princ` por cada argumento real.
- Operadores aritmeticos, relacionales y logicos.
- Sentencias `while`.
- Sentencias `if` e `if-else`.

El resultado fue un frontend capaz de generar programas Lisp ejecutables para un subconjunto basico de C.

### 3.2 Segunda ampliacion: `trad3.y`

En la tercera fase se completo el frontend con las construcciones restantes exigidas por la practica. El fichero de trabajo paso a ser `trad3.y`.

Las ampliaciones principales fueron:

- Variables locales.
- Bucle `for` usando las macros `INC(x)` y `DEC(x)`.
- Sentencia `switch`, con `case`, `default` y `break`.
- Funciones de usuario.
- Parametros de funcion.
- Llamadas a funciones.
- Sentencias `return`.
- Traduccion de retornos intermedios mediante `return-from`.
- Vectores globales y locales.
- Acceso a vectores mediante `aref`.
- Asignacion a posiciones de vector mediante `setf`.
- Tratamiento de cadenas con escapes basicos.

### 3.3 Backend: `back3.y`

El backend se implementa en `back3.y`. Su funcion es leer el Lisp generado por el frontend y producir codigo Forth.

Inicialmente el backend cubria solo una parte reducida de la especificacion: variables, asignaciones, impresion y operaciones aritmeticas. Posteriormente se completo para poder ejecutar la cadena completa sobre los programas de prueba, incluyendo soporte para funciones, parametros, retornos, llamadas y vectores.

---

## 4. Arquitectura general

El proyecto se organiza alrededor de dos traductores independientes:

- `trad3.y`: traductor frontend de C a Lisp.
- `back3.y`: traductor backend de Lisp a Forth.

Ambos ficheros contienen:

- Declaraciones de tokens.
- Atributos semanticos asociados a los simbolos de la gramatica.
- Reglas sintacticas.
- Acciones semanticas de generacion de codigo.
- Analizador lexico manual.
- Tabla de palabras reservadas.
- Funcion `main` que invoca `yyparse`.

La comunicacion entre ambos programas se realiza por entrada y salida estandar. Esto permite encadenarlos con pipes y facilita probar cada etapa por separado.

---

## 5. Frontend: traduccion de C a Lisp

### 5.1 Papel del frontend

El frontend recibe un programa escrito en el subconjunto de C soportado y genera codigo Lisp equivalente. Lisp se usa como codigo intermedio porque permite expresar de forma sencilla operaciones prefijas, llamadas a funcion, condicionales y estructuras de control.

Ejemplo simplificado:

```c
int a = 1;

main () {
    a = a + 2;
    printf("%d", a);
}

//@ (main)
```

Traduccion generada:

```lisp
(setq a 1)

(defun main ()
(setf a (+ a 2))
(princ a)
)

(main)
```

### 5.2 Analizador lexico

El analizador lexico de `trad3.y` reconoce:

- Identificadores de variables y funciones.
- Numeros enteros.
- Cadenas de texto.
- Palabras reservadas del subconjunto de C.
- Operadores simples y operadores compuestos.
- Directivas de preprocesador, que se ignoran.
- Comentarios normales `//`, que se ignoran.
- Directivas especiales `//@`, que se transcriben directamente a la salida.

La transcripcion de `//@` es importante para cumplir la especificacion del enunciado. La llamada a `main` no debe ser generada automaticamente por el traductor, sino aparecer en el programa C mediante:

```c
//@ (main)
```

Esto se transforma en:

```lisp
(main)
```

Posteriormente el backend lo traduce a:

```forth
main
```

### 5.3 Representacion mediante atributos

El frontend utiliza una estructura de atributos con campos como:

- `value`: valor numerico asociado a tokens como `NUMERO`.
- `code`: cadena con el codigo generado.
- `node`: campo heredado/preparado para arboles, aunque la traduccion final se basa principalmente en cadenas.

La generacion de codigo se realiza de forma dirigida por la sintaxis. Cada regla produce una cadena Lisp, y las listas de declaraciones o sentencias se construyen concatenando fragmentos.

Para evitar saltos de linea innecesarios y controlar mejor la salida se usan funciones auxiliares como:

- `gen_code`
- `combina_codigos`
- `append_codigo`
- `string_a_lisp`

### 5.4 Declaraciones globales

Las declaraciones globales `int` se traducen a `setq`.

Ejemplos:

```c
int a;
int b = 3;
int c = -2;
int v[10];
```

Se traducen como:

```lisp
(setq a 0)
(setq b 3)
(setq c -2)
(setq v (make-array 10))
```

Los vectores se representan en Lisp mediante `make-array`.

### 5.5 Funcion principal

La funcion principal se reconoce con la forma:

```c
main () {
    ...
}
```

Y se traduce a:

```lisp
(defun main ()
...
)
```

Siguiendo la especificacion final, `trad3` no anade por si solo la llamada `(main)`. Esa llamada debe aparecer mediante la directiva `//@ (main)`.

### 5.6 Variables locales

Las variables locales se traducen tambien con `setq`, pero se renombran usando como prefijo el nombre de la funcion actual. Esta decision evita colisiones entre variables locales de distintas funciones y variables globales.

Ejemplo:

```c
square (int v) {
    int resultado;
    resultado = v * v;
    return resultado;
}
```

La variable local `resultado` se representa como:

```lisp
(setq square_resultado 0)
```

Esta estrategia no implementa ambitos locales reales en Lisp ni Forth, pero es suficiente para mantener nombres diferenciados dentro del subconjunto de la practica.

### 5.7 Asignaciones

Las asignaciones en C se traducen a `setf`.

```c
a = b + 3;
```

Genera:

```lisp
(setf a (+ b 3))
```

Si la variable es local, se aplica el prefijo de funcion:

```lisp
(setf main_a (+ main_b 3))
```

### 5.8 Expresiones

El frontend convierte expresiones infijas de C en expresiones prefijas Lisp.

Ejemplos:

| C | Lisp |
|---|------|
| `a + b` | `(+ a b)` |
| `a - b` | `(- a b)` |
| `a * b` | `(* a b)` |
| `a / b` | `(/ a b)` |
| `a % b` | `(mod a b)` |
| `a == b` | `(= a b)` |
| `a != b` | `(/= a b)` |
| `a <= b` | `(<= a b)` |
| `a >= b` | `(>= a b)` |
| `a && b` | `(and a b)` |
| `a || b` | `(or a b)` |
| `!a` | `(not a)` |

La precedencia y asociatividad de operadores se gestionan mediante las declaraciones de precedencia de Bison.

### 5.9 Entrada y salida

`puts` se traduce a `print`:

```c
puts("Hola");
```

```lisp
(print "Hola")
```

`printf` se traduce generando un `princ` por cada argumento posterior a la cadena de formato:

```c
printf("%d %s", n, "texto");
```

```lisp
(princ n)
(princ "texto")
```

La cadena de formato no se interpreta de forma completa; se usa solo para respetar la sintaxis de C. La salida real depende de la lista de argumentos.

### 5.10 Estructuras de control

#### While

```c
while (condicion) {
    cuerpo
}
```

Se traduce como:

```lisp
(loop while condicion do
cuerpo)
```

#### If e if-else

```c
if (condicion) {
    bloque1
} else {
    bloque2
}
```

Se traduce usando `if` y `progn`:

```lisp
(if condicion
(progn
bloque1)
(progn
bloque2))
```

`progn` permite agrupar varias sentencias dentro de una rama.

#### For

El bucle `for` se implementa para la forma pedida en el enunciado, usando `INC` o `DEC`.

```c
for (i = 0; i < 10; INC(i)) {
    cuerpo
}
```

Se traduce a una inicializacion seguida de un `loop while`:

```lisp
(setf i 0)
(loop while (< i 10) do
cuerpo
(setf i (+ i 1)))
```

Para `DEC(i)` se genera una resta:

```lisp
(setf i (- i 1))
```

El traductor comprueba que la variable incrementada o decrementada sea la misma que la variable inicializada en el `for`.

#### Switch-case

La sentencia `switch` se traduce a `case` de Lisp.

```c
switch (x) {
    case 1:
        ...
        break;
    default:
        ...
        break;
}
```

Genera:

```lisp
(case x
(1
...)
(otherwise
...))
```

### 5.11 Funciones

El frontend reconoce funciones de usuario, parametros y llamadas.

```c
suma (int a, int b) {
    return a + b;
}
```

Se traduce como:

```lisp
(defun suma (a b)
(+ a b)
)
```

Las llamadas se traducen directamente:

```c
resultado = suma(2, 3);
```

```lisp
(setf resultado (suma 2 3))
```

### 5.12 Retornos

Cuando un `return` aparece como ultima sentencia de una funcion, se traduce como la expresion final de la funcion Lisp.

```c
return x + 1;
```

```lisp
(+ x 1)
```

Cuando aparece antes de otras sentencias, se traduce mediante `return-from` para preservar la salida anticipada.

```lisp
(return-from funcion expresion)
```

### 5.13 Vectores

Los vectores globales y locales se traducen mediante `make-array`.

```c
int v[5];
```

```lisp
(setq v (make-array 5))
```

El acceso se traduce con `aref`:

```c
v[i]
```

```lisp
(aref v i)
```

La asignacion a una posicion usa `setf`:

```c
v[i] = x;
```

```lisp
(setf (aref v i) x)
```

---

## 6. Backend: traduccion de Lisp a Forth

### 6.1 Papel del backend

El backend recibe el Lisp generado por `trad3` y produce codigo Forth. El codigo Forth se basa en una maquina de pila, por lo que las expresiones deben pasar de notacion prefija a notacion postfija.

Ejemplo:

```lisp
(+ a 3)
```

Se traduce como:

```forth
a @
3
+
```

En una forma mas compacta, la idea es:

```forth
a @ 3 +
```

### 6.2 Generacion diferida de codigo

Aunque el enunciado recomienda traduccion directa para el backend basico, la version final usa generacion diferida mediante cadenas. Esto facilita:

- Declarar variables antes de usarlas.
- Evitar que las llamadas a `main` se impriman antes de las definiciones.
- Construir correctamente funciones completas.
- Unificar la salida de expresiones, sentencias y bloques.

El axioma del backend no imprime codigo durante el reconocimiento de cada regla, sino al final, cuando ya se ha construido la secuencia completa. Primero imprime las declaraciones acumuladas y despues el codigo traducido.

### 6.3 Declaraciones

Las variables escalares se declaran con `variable`.

```lisp
(setq a 1)
```

Genera:

```forth
variable a
1 a !
```

Para evitar declaraciones duplicadas se mantiene una lista de nombres declarados.

Los vectores se declaran usando `create`, `cells` y `allot`:

```lisp
(setq v (make-array 5))
```

Genera:

```forth
create v 5 cells allot
```

Aunque los vectores no eran obligatorios en la parte basica del backend, se incorporaron para poder ejecutar los tests ampliados.

### 6.4 Acceso y asignacion de variables

En Forth, usar una variable como valor requiere `@`, mientras que asignar requiere `!`.

| Lisp | Forth |
|------|-------|
| `a` como expresion | `a @` |
| `(setf a 3)` | `3 a !` |
| `(setf a (+ b 1))` | `b @ 1 + a !` |

El backend distingue entre identificadores normales y parametros de funcion. Los parametros se manejan como locales de Forth, por lo que no se acceden con `@`.

### 6.5 Parametros de funcion

Las funciones con parametros se traducen usando locales de Gforth:

```lisp
(defun cuadrado (n)
(* n n)
)
```

Genera:

```forth
: cuadrado recursive { n -- }
n
n
*
;
```

El uso de `recursive` permite que una funcion pueda llamarse a si misma, algo necesario en pruebas como factorial o Fibonacci.

### 6.6 Llamadas a funcion

Las llamadas Lisp se traducen evaluando primero sus argumentos y despues emitiendo el nombre de la funcion.

```lisp
(suma 2 3)
```

Genera:

```forth
2
3
suma
```

Esto encaja con el modelo de pila de Forth: los argumentos quedan en la pila antes de ejecutar la palabra correspondiente.

### 6.7 Retornos

El retorno normal de una funcion se representa dejando el valor en la pila. Por eso, si el `return` era la ultima sentencia de la funcion C, el frontend genera directamente la expresion Lisp final.

Para retornos anticipados, el frontend genera `return-from` y el backend lo traduce como:

```forth
expresion
exit
```

La palabra `exit` abandona la definicion actual de Forth dejando en la pila el valor calculado.

### 6.8 Impresion

La impresion de cadenas usa `." ..."` y `cr` para salto de linea:

```lisp
(print "Hola")
```

```forth
." Hola" cr
```

La impresion de enteros usa `.`:

```lisp
(princ x)
```

```forth
x @
.
```

Si `princ` recibe una cadena, se genera una impresion sin salto de linea.

### 6.9 Expresiones aritmeticas y logicas

El backend convierte la notacion prefija de Lisp en notacion postfija de Forth.

| Lisp | Forth |
|------|-------|
| `(+ a b)` | `a @ b @ +` |
| `(- a b)` | `a @ b @ -` |
| `(* a b)` | `a @ b @ *` |
| `(/ a b)` | `a @ b @ /` |
| `(mod a b)` | `a @ b @ mod` |
| `(and a b)` | `a @ b @ and` |
| `(or a b)` | `a @ b @ or` |
| `(not a)` | `a @ 0=` |
| `(= a b)` | `a @ b @ =` |
| `(/= a b)` | `a @ b @ = 0=` |
| `(< a b)` | `a @ b @ <` |
| `(<= a b)` | `a @ b @ <=` |
| `(> a b)` | `a @ b @ >` |
| `(>= a b)` | `a @ b @ >=` |

### 6.10 Estructuras de control

#### While

Lisp:

```lisp
(loop while condicion do
cuerpo)
```

Forth:

```forth
begin
condicion
while
cuerpo
repeat
```

#### If

Lisp:

```lisp
(if condicion
(progn
bloque1)
(progn
bloque2))
```

Forth:

```forth
condicion
if
bloque1
else
bloque2
then
```

Para el caso sin `else` se genera:

```forth
condicion
if
bloque
then
```

### 6.11 Directiva de llamada a main

El backend no debe generar automaticamente una llamada a `main`. Si el Lisp contiene:

```lisp
(main)
```

Entonces se traduce simplemente a:

```forth
main
```

Esto permite que el control sobre la ejecucion del programa quede en el fichero C original mediante la directiva `//@ (main)`.

---

## 7. Integracion frontend-backend

La integracion de las dos partes se basa en que `trad3` genere un Lisp suficientemente regular para que `back3` pueda reconocerlo.

Ejemplo completo:

```c
cuadrado (int n) {
    return n * n;
}

main () {
    printf("%d", cuadrado(4));
}

//@ (main)
```

Salida intermedia Lisp:

```lisp
(defun cuadrado (n)
(* n n)
)

(defun main ()
(princ (cuadrado 4))
)

(main)
```

Salida Forth:

```forth
: cuadrado recursive { n -- }
n
n
*
;
: main recursive
4
cuadrado
.
;
main
```

---

## 8. Problemas encontrados y soluciones

### 8.1 Llamada a `main`

Durante el desarrollo se planteo anadir automaticamente `(main)` al final del frontend. Sin embargo, el enunciado final especifica que la llamada a `main` debe gestionarse exclusivamente con la directiva:

```c
//@ (main)
```

Por tanto, se mantiene esta directiva como mecanismo correcto. Esto evita ejecutar programas que solo deban traducirse parcialmente y respeta la cadena de evaluacion indicada por la practica.

### 8.2 Orden de impresion en el backend

Si el backend imprime codigo directamente durante el parseo, una llamada `(main)` puede aparecer antes de la definicion de la funcion `main`. Para evitarlo, el backend construye el codigo completo y lo imprime al final.

Esto tambien permite acumular las declaraciones globales y emitirlas antes de las funciones.

### 8.3 Funciones genericas

El backend inicial solo trataba correctamente el caso de `main`. Los tests de funciones fallaban porque aparecian definiciones como:

```lisp
(defun cuadrado (n) ...)
```

Y llamadas como:

```lisp
(cuadrado 4)
```

La solucion fue anadir reglas para:

- `defun` con identificador generico.
- Lista de parametros.
- Lista de argumentos.
- Llamadas a funcion como expresiones.
- Llamadas a funcion como sentencias.

### 8.4 Parametros y variables

En Forth no se accede igual a una variable declarada con `variable` que a un parametro local. Por eso el backend mantiene una lista de parametros de la funcion actual.

- Si el identificador es parametro, se usa directamente.
- Si no lo es, se usa como variable global con `@` o `!`.

### 8.5 Recursion

Las pruebas incluyen funciones recursivas. En Forth, para permitir llamadas recursivas dentro de una definicion, se usa `recursive`.

Por ese motivo, las funciones generadas siguen este esquema:

```forth
: nombre recursive ...
;
```

### 8.6 Retornos anticipados

Cuando el frontend genera `return-from`, el backend debe abandonar la funcion actual. La traduccion elegida es calcular la expresion y despues emitir `exit`.

### 8.7 Salida final sin salto de linea

Se detecto que, al ejecutar:

```bash
cat tests-2026/01/funciones4.c | ./trad3 | ./back3 | gforth
```

`gforth` podia quedarse esperando o generar salida de control si el ultimo token no terminaba con salto de linea. Se corrigio haciendo que `back3` termine siempre su salida con `\n`.

### 8.8 Coste de programas recursivos

El test `tests-2026/03/fibonacci1.c` calcula Fibonacci de forma recursiva ingenua hasta valores altos. El programa traducido produce resultados correctos hasta donde llega, pero con un `timeout` corto no finaliza. Se comprobo que el mismo programa compilado en C tambien supera el timeout usado en las pruebas locales, por lo que se trata de un problema de coste del algoritmo, no de sintaxis del traductor.

---

## 9. Pruebas realizadas

### 9.1 Compilacion

Los traductores se compilan con:

```bash
bison -d -v trad3.y
gcc -o trad3 trad3.tab.c

bison -d -v back3.y
gcc -o back3 back3.tab.c
```

### 9.2 Pruebas manuales

Se han usado programas propios como `pruebas.c`, que combina:

- Variables globales.
- Variables locales.
- Operaciones aritmeticas.
- Operaciones logicas y relacionales.
- `puts`.
- `printf`.
- `if-else`.
- `while`.
- `for` ascendente y descendente.
- Vectores globales y locales.
- Funciones con parametros.
- Funciones con retorno.
- Recursion.
- Llamadas anidadas.

Este fichero sirve como prueba amplia de integracion del frontend.

### 9.3 Pruebas oficiales/locales `tests-2026`

Se ejecuto la cadena completa sobre los ficheros `.c` de `tests-2026`:

```bash
cat tests-2026/01/funciones1.c | ./trad3 | ./back3 | gforth
```

Y de forma automatizada para todos los ficheros:

```bash
find tests-2026 -type f -name "*.c" | sort
```

Categorias cubiertas:

| Carpeta | Tipo de pruebas | Resultado |
|---------|------------------|-----------|
| `00` | Funcionalidad basica: `puts`, `printf`, `while`, factorial, primos | Correcto |
| `01` | Funciones simples y llamadas | Correcto |
| `02` | Funciones, vectores, primos y potencias | Correcto |
| `03` | Recursion y programas mas costosos | Correcto salvo coste elevado de `fibonacci1.c` |

El caso `fibonacci1.c` no fallo por error de traduccion, sino por tiempo de ejecucion. Con timeout corto se detiene mientras sigue calculando valores de Fibonacci recursivo. El mismo comportamiento se observa al compilar y ejecutar el programa C original con un limite de tiempo equivalente.

---

## 10. Limitaciones actuales

El proyecto no pretende implementar C completo. Se limita al subconjunto de la practica. Las principales limitaciones son:

- Solo se soporta el tipo entero `int`.
- No hay comprobacion semantica completa de tipos.
- No se soportan punteros, estructuras, `char`, `float`, `double` ni arrays multidimensionales.
- Las variables locales se renombran con prefijo de funcion en lugar de implementarse como ambitos reales.
- El frontend soporta `switch-case` traduciendolo a `case` de Lisp, pero el backend actual no implementa una traduccion completa de `case` a Forth.
- El tratamiento de `printf` no interpreta realmente los especificadores de formato, sino que imprime los argumentos en orden.
- Los vectores se traducen con tamano fijo conocido en declaracion.
- El analizador lexico esta adaptado al subconjunto esperado y no pretende cubrir todos los casos validos de C.
- La generacion de codigo usa buffers de tamano fijo en algunas partes, suficiente para las pruebas manejadas pero no para programas arbitrariamente grandes.

---

## 11. Correspondencia resumida entre C, Lisp y Forth

| C | Lisp | Forth |
|---|------|-------|
| `int a = 1;` | `(setq a 1)` | `variable a` + `1 a !` |
| `a = b + 1;` | `(setf a (+ b 1))` | `b @ 1 + a !` |
| `puts("x");` | `(print "x")` | `." x" cr` |
| `printf("%d", a);` | `(princ a)` | `a @ .` |
| `while (c) { s }` | `(loop while c do s)` | `begin c while s repeat` |
| `if (c) { a } else { b }` | `(if c (progn a) (progn b))` | `c if a else b then` |
| `f(x);` | `(f x)` | `x f` |
| `return x;` | `x` o `(return-from f x)` | `x` o `x exit` |
| `v[i]` | `(aref v i)` | `v i cells + @` |
| `v[i] = x;` | `(setf (aref v i) x)` | `x v i cells + !` |

---

## 12. Conclusiones

El proyecto queda estructurado como un traductor en dos fases. La primera fase, `trad3`, transforma un subconjunto de C en Lisp, resolviendo la mayor parte de la complejidad sintactica de C: precedencia de operadores, sentencias, funciones, variables locales y vectores. La segunda fase, `back3`, toma ese Lisp intermedio y lo convierte en Forth, adaptando la evaluacion al modelo de pila.

La division frontend-backend permite razonar mejor sobre el problema. El frontend trabaja con un lenguaje fuente mas complejo y genera una forma intermedia uniforme. El backend se apoya en esa regularidad para producir notacion postfija.

Las pruebas realizadas muestran que la cadena:

```bash
cat prueba.c | ./trad3 | ./back3 | gforth
```

funciona correctamente para la bateria principal de `tests-2026`, incluyendo pruebas de funciones, recursion, bucles, impresion y vectores. El caso mas costoso detectado, `fibonacci1.c`, queda identificado como una limitacion temporal derivada del algoritmo recursivo exponencial utilizado en el propio programa de prueba.

En conjunto, el proyecto cumple el objetivo de traducir y ejecutar programas del subconjunto de C propuesto, manteniendo una arquitectura clara y extensible basada en codigo intermedio Lisp y salida final Forth.

