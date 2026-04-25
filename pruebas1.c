int a = 1;
int b = 2;
int c = 5;

main () {
    int d = 10;
    int i = 0;
    int opcion = 2;
    printf("%d", a + 1);
    a = 2 != 3 ;
    d = d + a ;
    c = 3;
    a = 2 * 3;
    a = 2;
    while (a < 5) {
        if (a == 2 && c == 3) {
            puts("a es un dos");
            b = 100;
        } else {
            printf("%d", a);
            b = 0;
        }
        printf("%d", b);
        a = a + 1;
    }
    for ( i = 0; i < d; INC(i) ) {
        c = c - 1;
    }
    switch (opcion) {
        case 1:
            puts("Elegiste la opcion 1");
            break;
        case 2:
            puts("Elegiste la opcion 2");
            opcion = opcion + 10;
            break;
        default:
            puts("Opcion no reconocida");
            break;
    }
}

//@ (main)
