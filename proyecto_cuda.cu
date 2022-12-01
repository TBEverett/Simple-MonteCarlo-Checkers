#include <iostream>
#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <stdlib.h>
#include "funciones.h"

using namespace std;

__global__ void kernel(float* Ain, float* Aout, int M, int N, float deltax){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    if (tid < M*N){
        int tid_left = (!(tid % N)) ? (tid + N - 1) : (tid - 1);
        int tid_right = (!(tid % (N-1))) ? (tid - N + 1) : (tid + 1);
        Aout[tid] = Ain[tid] + (Ain[tid_right] - Ain[tid_left])/(2*deltax);
    }
}

/* ----   Codigo Principal ---- */
 

int main(int argc, char** argv) {

    // Variables que trabajaremos 
    int N = 8;
    int* board = new int[N*N];
    int n_fichas = 0;
    
    //Construccion de tablero inicial
    int filas_con_fichas = (N-2)/2;
    for (int i = 0; i < N*N; i++){
        board[i] = 0;
        if (i/N < filas_con_fichas){
            if ((i/N)%2){
                if (!(i%2)) board[i] = 2;
            }
            else{
                if (i%2) board[i] = 2;
            } 
        }
        else if (i/N > filas_con_fichas + 1){
            if (!(i/N%2)){
                if (i%2){
                    board[i] = 1;
                    n_fichas++;
                } 
            }
            else{
                if (!(i%2)){
                    n_fichas++;
                    board[i] = 1;
                }
            } 
        }
    }
    board[24] = 1;
    printBoard(board,N);
    int turno_jugador = 2;
    Movimientos* movimientos = generarMovimientos(board, N, n_fichas, turno_jugador);
    for(int i = 0; i < movimientos->length; i++){
        cout << movimientos->listaMovimientos[i].start_position << " " << movimientos->listaMovimientos[i].end_position << endl;
    }


    
    //Juego versión CPU


    

    bool flag_finalizado = false;
    int turno_jugador = 1; //turno_jugador 1 es del jugador
    Movimientos* movimientos;
    while(!flag_finalizado){
        printBoard(board, N);
        movimientos = generarMovimientos(board, N, n_fichas, turno_jugador);
        //Permitir a jugador escoger movimientos

        turno_jugador = (turno_jugador % 2) + 1;

        //Generar movimientos contrincante 
        //Escoger movimientos contrincante (IA)
        //if (JuegoFinalizado()) flag_finalizado = true;
    }






/*
    



    
    
	float dt;
	int gs, bs = 256;
	gs = (int)ceil((float) N*N/bs);

    
    clock_t start = clock();
    //JogodeDamas(Ain, Aout, M, N, deltax);
    clock_t end = clock();
    float seconds = (float)(end - start) / CLOCKS_PER_SEC;
    printf("Tiempo CPU: %f [ms]\n",seconds*1000);
   
    


    float* AinGPU;
    float* AoutGPU;

    cudaMalloc((void**)&AinGPU, N * M * sizeof(float));
    cudaMalloc((void**)&AoutGPU, N * M * sizeof(float));

    cudaEvent_t e1, e2;
    cudaEventCreate(&e1);
    cudaEventCreate(&e2);
    cudaEventRecord(e1);
    

    cudaMemcpy(AinGPU, Ain, N * M * sizeof(float), cudaMemcpyHostToDevice);
    kernel << <gs, bs >> > (AinGPU, AoutGPU, M, N, deltax);
    cudaMemcpy(Aout, AoutGPU, M * N * sizeof(float), cudaMemcpyDeviceToHost);
    Ain = Aout;
    

    cudaEventRecord(e2);
    cudaEventSynchronize(e2);
    cudaEventElapsedTime(&dt, e1, e2);
    std::cout << "Tiempo GPU Sin Streams: " << dt << " [ms]" << std::endl;

	cudaFree(AinGPU); cudaFree(AoutGPU);
	delete[] Ain;
    
    */
}