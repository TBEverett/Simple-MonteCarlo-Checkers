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
    int n_fichas_IA = 0;
    srand(time(NULL));
    
    //Construccion de tablero inicial
    build_board(board, N, &n_fichas_player, &n_fichas_IA);

    // Juego version CPU, IA random
    bool flag_finalizado = false;
    int turno_jugador = 1; //turno_jugador 1 es del jugador
    Movimientos* movimientos;
    Move player_move;
    Move IA_move;
    while(!flag_finalizado){
        //Turno del jugador
        system("clear");
        printBoard(board, N);
        movimientos = generarMovimientos(board, N, n_fichas_player, turno_jugador);
        if (movimientos->length == 0){
            printBoard(board, N);
            printf("Ha ganado la Inteligencia Articial. La era del hombre ha llegado a su fin");
            flag_finalizado = true;
        } 
        player_move = player_select_move(movimientos, N);
        freeMovimientos(movimientos);
        execute_movement(board, N, player_move, &n_fichas_IA);  

        //Turno de la IA
        turno_jugador = (turno_jugador % 2) + 1; 
        movimientos = generarMovimientos(board, N, n_fichas_IA, turno_jugador);
        if (movimientos->length == 0){
            printBoard(board, N);
            printf("Ha ganado el jugador humano, venciendo a Skynet.");
            flag_finalizado = true;
        } 
        //Simulamos para cada movimiento
        int NTHREADS = 100;
        int indice_maximo = 0;
        float eval_maxima = 0.;
        float eval_actual = 0.;
        for(int i = 0; i < movimientos->length; i++){
            for (int j = 0; j < NTHREADS; j++){
                eval_actual += MonteCarloSimulation(board, N, movimientos->listaMovimientos[i], n_fichas_player, n_fichas_IA); //Simulacion en CPU de 1 solo hilo retornará -1 o 1
            }
            printf("(%d-%d,",movimientos->listaMovimientos[i].start_position / N , movimientos->listaMovimientos[i].start_position % N);
            printf("%d-%d)",movimientos->listaMovimientos[i].end_position / N ,movimientos->listaMovimientos[i].end_position % N);
            
            eval_actual = (eval_actual/NTHREADS) * 100;
            printf("Evaluacion : %d%c\n ", (int) eval_actual, '%');
            if (eval_actual > eval_maxima){
                indice_maximo = i;
                eval_maxima = eval_actual;
            }
            eval_actual = 0;
        } 
        //system("pause");
        IA_move = movimientos->listaMovimientos[indice_maximo];
        execute_movement(board, N, IA_move, &n_fichas_player); 
        freeMovimientos(movimientos); 
        turno_jugador = (turno_jugador % 2) + 1;

        //Revisión de win condition 
        if (win(board,N) == 0){
            printf("Ha ganado el jugador humano, venciendo a Skynet.");
            flag_finalizado = true;
            
        }
        else if (win(board,N) == 1){
            printf("Ha ganado la Inteligencia Articial. La era del hombre ha llegado a su fin");
            flag_finalizado = true;
        }
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