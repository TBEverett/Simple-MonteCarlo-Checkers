#include <iostream>
//#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <stdlib.h>
#include "funciones.h"

using namespace std;

/*
__global__ void kernel(float* Ain, float* Aout, int M, int N, float deltax){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    if (tid < M*N){
        int tid_left = (!(tid % N)) ? (tid + N - 1) : (tid - 1);
        int tid_right = (!(tid % (N-1))) ? (tid - N + 1) : (tid + 1);
        Aout[tid] = Ain[tid] + (Ain[tid_right] - Ain[tid_left])/(2*deltax);
    }
}

*/

/* ----   Codigo Principal ---- */
 

int main(int argc, char** argv) {

    // Variables que trabajaremos 
    int N = 8;
    int* board = new int[N*N];
    int n_fichas_player = 0;
    int n_fichas_rival = 0;
    srand(time(NULL));
    
    //Construccion de tablero inicial
    build_board(board, N, &n_fichas_player, &n_fichas_rival);

    // Juego version CPU, IA random
    bool flag_finalizado = false;
    int turno_jugador = 1; //turno_jugador 1 es del jugador
    Movimientos* movimientos;
    Move player_move;
    Move IA_move;
    while(!flag_finalizado){
        system("clear");
        printBoard(board, N);
        movimientos = generarMovimientos(board, N, n_fichas_player, turno_jugador);
        player_move = player_select_move(movimientos, N);
        freeMovimientos(movimientos);

        execute_movement(board, N, player_move, &n_fichas_player);  

        
        turno_jugador = (turno_jugador % 2) + 1; 

        movimientos = generarMovimientos(board, N, n_fichas_rival, turno_jugador);
        
        IA_move = movimientos->listaMovimientos[rand() % movimientos->length]; //Por ahora random
        //IA_move = montecarloMove(board, N, n_fichas_player, n_fichas_rival, turno_jugador);

        printf( "start pos: d%", IA_move.start_position);

        execute_movement(board, N, IA_move, &n_fichas_rival); 
        freeMovimientos(movimientos); 

        turno_jugador = (turno_jugador % 2) + 1;

    
      /*
       ////////////////////////////////////////
        if (eval(board,N) == -1){
            printBoard(board, N);
            printf("Ha ganado el jugador 1");
            flag_finalizado = true;
            
        }

        else if (eval(board,N) == -2){
            printBoard(board, N);
            printf("Ha ganado el jugador 2");
            flag_finalizado = false;
            
        }
        */

    }
        ///////////////////////////////////////
    
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