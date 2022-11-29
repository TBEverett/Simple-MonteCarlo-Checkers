
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

struct Nodo{
    int* solucion;
    Nodo* izq;
    Nodo* der;
};

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

//Funcion que escoge un movimiento al azar