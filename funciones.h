
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

struct Nodo{
    int* solucion;
    Nodo* izq;
    Nodo* der;
};

struct Move{
    int start_position;
    int end_position;
    int kill;
};

struct Movimientos{
    Move* listaMovimientos;
    int length; 
};

//Necesitaremos una función que transforme coordenadas de start_position/end_position en algo como A8

void printBoard(int* board, int N){
    cout << "   ";
    for (int i = 0; i <= 2*N; i++){
        if (i == N) cout << endl << "   ";
        else if (i < N) cout << i << " ";
        else if (i > N) cout << "- ";    
    }
    cout << endl;
    for (int j = 0; j < N; j++){
        cout << j << "| ";
        for(int i = 0; i < N; i++){
            cout << board[i +  j*N] << " ";
        }
        cout << endl;
    }
}

//Funcion de evaluación (o quizas se gana instantaneamente al llegar a la fila enemiga)
float eval(int *board, int N){
    int one_fichas = 0;
    int two_fichas = 0;
    int diff = 0;
    
    for(int i = 0; i < N; i++){
       for(int j = 0; j < N; j++){
            if (board[i*N + j] == 2){
                if(i == (N - 1)) return -2;
                else two_fichas++;
            }

            else if (board[i*N + j] == 1) {
                if(i == 0) return -1;
                else one_fichas++;
            }    
       }  
    }

    diff = two_fichas - one_fichas;
    if(diff > 0)  return 2 * diff; // El doble de la diferencia cuando se poseen mas fichas que el rival
    else if (diff == 0) return 1;   // 1 cuando se empata en fichas
    else return (1.0 * N / (N -  diff)); // Entre 0 y 1 cuando se pierde en fichas 

}


//Funcion que permite al jugador escoger su movimiento
Move player_select_move(Movimientos* movimientos, int N){
    cout << "Movimientos que puede realizar: " << endl;
    for(int i = 0; i < movimientos->length; i++){
        printf("%d: ", i+1);
        printf("(%d-%d,",movimientos->listaMovimientos[i].start_position / N , movimientos->listaMovimientos[i].start_position % N);
        printf("%d-%d)\n",movimientos->listaMovimientos[i].end_position / N ,movimientos->listaMovimientos[i].end_position % N);
    }
    int eleccion;
    printf("Ingrese su eleccion: ");
    scanf("%d",&eleccion);
    return {movimientos->listaMovimientos[eleccion-1].start_position,movimientos->listaMovimientos[eleccion-1].end_position,movimientos->listaMovimientos[eleccion-1].kill};
}

//Función que ejecuta un movimiento sobre el tablero. Asume que el movimiento siempre es factible.
void execute_movement(int* &board, int N, Move movimiento){
    board[movimiento.end_position] = board[movimiento.start_position];
    board[movimiento.start_position] = 0;
    if (movimiento.kill != -1) board[movimiento.kill] = 0;
}


//Función que retorna una lista con movimientos
Movimientos* generarMovimientos(int* board, int N, int n_fichas, int ficha_aliada){ //n_fichas (de 1 jugador) nos servirá para dejar de buscar cuando hayamos procesado todas las fichas
    int colum;

    int aux_numero_fichas = n_fichas;

    Movimientos* movimientos = new Movimientos; //Acotamos la cantidad de movimientos (cantidad de fichas * 2)
    movimientos -> listaMovimientos = new Move[n_fichas * 2];
    movimientos -> length = 0;
    int direccion_mov;
    int ficha_rival;
    if (ficha_aliada == 1){
        direccion_mov = -1;
        ficha_rival = 2;
    } 
    else{
        direccion_mov = 1;
        ficha_rival = 1;
    }
    for(int i = 0; i < N*N; i++){
        colum = i % N;
        //Encontramos una ficha aliada
        if (board[i] == ficha_aliada){
            //Si es que estamos en el borde izquierdo
            if (colum == 0){
                //Si derecha esta libre, agregamos el movimiento
                if (board[i + 1 + N*direccion_mov] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {i,i + 1 + N*direccion_mov,-1};
                    movimientos -> length++;
                }
                //Si derecha ocupada pero hay ficha rival y puede comersela, es un movimiento
                else if ((board[i + 1 + N*direccion_mov] == ficha_rival) && (i + 2 + 2*N*direccion_mov > 0)){
                    if (board[i + 2 + 2*N*direccion_mov] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {i,i + 2 + 2*N*direccion_mov,i + 1 + N*direccion_mov};
                        movimientos -> length++;
                    }
                }
            }
            //Si es que estamos en el borde derecho
            else if(colum == N-1){
                //Si izquierda esta libre, agregamos el movimiento
                if (board[i - 1 + N*direccion_mov] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {i,i - 1 + N * direccion_mov,-1};
                    movimientos -> length++;
                }
                //Si izquierda ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[i - 1 + N * direccion_mov] == ficha_rival) && (i - 2 + 2*N*direccion_mov > 0)){
                    if (board[i - 2 + 2*N*direccion_mov] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {i,i - 2 + 2*N*direccion_mov,i - 1 + N*direccion_mov};
                        movimientos -> length++;
                    }
                }
            }
            else{
                //Si izquierda arriba esta libre, agregamos el movimiento
                if (board[i - 1 + N*direccion_mov] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {i,i - 1 + N*direccion_mov,-1};
                    movimientos -> length++;
                }
                //Si izquierda arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[i - 1 + N*direccion_mov] == ficha_rival) && (i - 2 + 2*N*direccion_mov> 0)){
                    if (board[i - 2 + 2*N*direccion_mov] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {i,i - 2 + 2*N*direccion_mov,i - 1 + N*direccion_mov};
                        movimientos -> length++;
                    }
                }
                //Si derecha arriba esta libre, agregamos el movimiento
                if (board[i + 1 + N*direccion_mov] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {i,i + 1 + N*direccion_mov,-1};
                    movimientos -> length++;
                }
                //Si derecha arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[i + 1 + N*direccion_mov] == ficha_rival) && (i + 2 + 2*N*direccion_mov> 0)){
                    if (board[i + 2 + 2*N*direccion_mov] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {i,i + 2 + 2*N*direccion_mov,i + 1 + N*direccion_mov};
                        movimientos -> length++;
                    }
                }
            }
        aux_numero_fichas--;
        if (aux_numero_fichas == 0) break;
        }
    }
    return movimientos;
}

//Funcion que escoge un movimiento al azar