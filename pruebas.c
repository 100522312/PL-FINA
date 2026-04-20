int a = 1, b, c = 5, flag = 0;
int vg[5];

saluda () {
    puts("Saludo desde funcion");
}

square (int v) {
    return (v * v);
}

suma3 (int x, int y, int z) {
    int total = 0;
    total = x + y + z;
    return total;
}

clasifica (int x) {
    if (x == 0) {
        return 0;
    }
    return 1;
}

fact (int n) {
    int f = 0;
    if (n == 1) {
        f = 1;
    } else {
        f = n * fact(n - 1);
    }
    return f;
}

is_even (int v) {
    int ep = 0;
    printf("%d", v);
    if (v % 2 == 0) {
        puts(" es par");
        ep = 1;
    } else {
        puts(" es impar");
        ep = 0;
    }
    return ep;
}

main () {
    int i = 0, j = 3, opcion = 0, otro = 7, suma = 0, valor = 0;
    int vl[4];

    puts("Inicio");
    puts("Linea 1\nLinea 2");
    puts("Comillas: \"ok\"");
    saluda();
    opcion = -1;
    printf("%d %s", a + c, " <- suma inicial\n");
    printf("%s", "Texto con\nsalto\n");
    printf("%s", "Ruta C:\\tmp\\fichero\n");
    printf("%s", "Cadena con \"comillas\"");

    b = a + c * 2;
    c = (b - 3) / 2;
    suma = b % 4;
    printf("%d", suma);

    if ((a < b && c >= 3) || !(flag == 1)) {
        puts("Condicion verdadera");
        flag = 1;
    } else {
        puts("Condicion falsa");
        flag = 0;
    }

    while (a <= 3) {
        printf("%d", a);
        a = a + 1;
    }

    vg[0] = 10;
    vg[1] = 20;
    vg[2] = vg[0] + vg[1];
    printf("%d %s", vg[2], " <- vector global   ");

    vl[0] = 1;
    vl[1] = 2;
    vl[i + 2] = vg[2] - 5;
    printf("%d %s", vl[2], " <- vector local    ");

    for (i = 0; i < 3; INC(i)) {
        puts("For ascendente");
        suma = suma + i;
    }

    for (j = 3; j > 0; DEC(j)) {
        puts("For descendente");
        suma = suma + j;
    }

    if (suma != 0 && b > a && c <= b) {
        printf("%d %s", suma, " <- suma acumulada");
    } else {
        puts("Error en suma");
    }

    switch (opcion) {
        case -1:
            puts("Caso negativo");
            otro = otro - 1;
            break;
        case 2:
            puts("Caso dos");
            otro = otro + 10;
            break;
        default:
            puts("Default no esperado");
            break;
    }

    switch (otro) {
        case 0:
            puts("Cero");
            break;
        default:
            puts("Default alcanzado");
            break;
    }

    valor = square(7);
    printf("%d %s", valor, " <- square  ");
    printf("%d %s", fact(5), " <- fact  ");
    printf("%d %s", suma3(1, 2, 3), " <- suma3  ");
    printf("%d %s", clasifica(0), " <- clasifica cero   ");
    printf("%d %s", clasifica(9), " <- clasifica no cero    ");
    printf("%d %s", is_even(7), " <- is_even 7  ");
    printf("%d %s", square(vg[1]), " <- square vector   ");
    printf("%d %s", vg[0] + vl[1], " <- expr con vectores   ");
    is_even(8);

    printf("%d %s", otro, " <- valor final");
}
