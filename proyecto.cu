
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include "funciones.h"
using namespace std;

int main(){
    //Versión simple de juego de damas
    int N = 16;
    int* board = new int[N*N];
    
    int filas_con_fichas = (N-2)/2;
    //Construccion de tablero inicial
    for (int i = 0; i < N*N; i++){
        board[i] = 0;
        if (i/N < filas_con_fichas){ //Hardcodeado el 3, podría depender de N para N damas.
            if ((i/N)%2){
                if (!(i%2)) board[i] = 1;
            }
            else{
                if (i%2) board[i] = 1;
            } 
        }
        else if (i/N > filas_con_fichas + 1){
            if (!(i/N%2)){
                if (i%2) board[i] = 2;
            }
            else{
                if (!(i%2)) board[i] = 2;
            } 
        }
    }
    printBoard(board, N);






}