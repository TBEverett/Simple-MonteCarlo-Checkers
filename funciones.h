
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
    for (int j = 0; j < N; j++){
        for(int i = 0; i < N; i++){
            cout << board[i +  j*N] << " ";
        }
        cout << endl;
    }
}

//Funcion de evaluación (o quizas se gana instantaneamente al llegar a la fila enemiga)
float eval(int* board, int N);

//Función que retorna una lista con movimientos
Movimientos* generarMovimientos(int* board, int N, int n_fichas){ //n_fichas (de 1 jugador) nos servirá para dejar de buscar cuando hayamos procesado todas las fichas
    int colum;
    int fila;

    int aux_numero_fichas = n_fichas;

    Movimientos* movimientos = new Movimientos; //Acotamos la cantidad de movimientos (cantidad de fichas * 2)
    movimientos -> listaMovimientos = new Move[n_fichas * 2];
    movimientos -> length = 0;
    for(int i = 0; i < N*N; i++){
        colum = i % N;
        fila = i / N;

        //Encontramos una ficha aliada
        if (board[colum + N*fila] == 2){
            //Si es que estamos en el borde izquierdo
            if (colum == 0){
                //Si derecha arriba esta libre, agregamos el movimiento
                if (board[colum + N*fila + 1 - N] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila + 1 - N,-1};
                    movimientos -> length++;
                }
                //Si derecha arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[colum + N*fila + 1 - N] == 1) && (colum + N*fila + 2 - 2*N > 0)){
                    if (board[colum + N*fila + 2 - 2*N] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila + 2 - 2*N,colum + N*fila + 1 - N};
                        movimientos -> length++;
                    }
                }
            }
            //Si es que estamos en el borde derecho
            else if(colum == N-1){
                //Si izquierda arriba esta libre, agregamos el movimiento
                if (board[colum + N*fila - 1 - N] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila - 1 - N,-1};
                    movimientos -> length++;
                }
                //Si izquierda arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[colum + N*fila - 1 - N] == 1) && (colum + N*fila - 2 - 2*N > 0)){
                    if (board[colum + N*fila - 2 - 2*N] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila - 2 - 2*N,colum + N*fila - 1 - N};
                        movimientos -> length++;
                    }
                }
            }
            else{
                //Si izquierda arriba esta libre, agregamos el movimiento
                if (board[colum + N*fila - 1 - N] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila - 1 - N,-1};
                    movimientos -> length++;
                }
                //Si izquierda arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[colum + N*fila - 1 - N] == 1) && (colum + N*fila - 2 - 2*N > 0)){
                    if (board[colum + N*fila - 2 - 2*N] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila - 2 - 2*N,colum + N*fila - 1 - N};
                        movimientos -> length++;
                    }
                }
                //Si derecha arriba esta libre, agregamos el movimiento
                if (board[colum + N*fila + 1 - N] == 0){
                    (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila + 1 - N,-1};
                    movimientos -> length++;
                }
                //Si derecha arriba ocupada pero ficha y puede comersela, es un movimiento
                else if ((board[colum + N*fila + 1 - N] == 1) && (colum + N*fila + 2 - 2*N > 0)){
                    if (board[colum + N*fila + 2 - 2*N] == 0){
                        (movimientos -> listaMovimientos)[movimientos -> length] = {colum + N*fila,colum + N*fila + 2 - 2*N,colum + N*fila + 1 - N};
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