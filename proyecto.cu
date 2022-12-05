#include <iostream>
#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <stdlib.h>
#include "funciones.h"
#include <curand_kernel.h>

using namespace std;


__global__ void kernel(int* board, int N, int start_position, int end_position, int kill, int n_fichas_player, int n_fichas_IA, float* evaluacion_total){
    curandState state;
    curand_init(clock64(), threadIdx.x + blockDim.x * blockIdx.x, 0, &state);

    //Creamos copia local del tablero
    int* local_board = new int[N*N];
    for(int i = 0; i < N*N; i++) local_board[i] = board[i];

    Move movimiento = {start_position,end_position, kill};
    //Aplicamos movimiento a tablero local
    execute_movement(local_board, N, movimiento, &n_fichas_player);

    //Ahora simulamos movimientos para ambos jugadores hasta que alguien gane.
    int turno_jugador = 1; //turno_jugador 1 es del jugador
    Movimientos* movimientos = new Movimientos;
    movimientos->length = 0;
    movimientos->listaMovimientos = new Move[2 * (n_fichas_IA + n_fichas_player)]; //Cantidad de movimientos es acotada
    Move player_move;
    Move IA_move;
    float winner;
    int iter = 0;
    int random;
    while(true){
            
        //Turno simulado del jugador
        movimientos = generarMovimientos(local_board, N, n_fichas_player, turno_jugador, movimientos);
        if (movimientos->length == 0){ //Si jugador se queda sin movimientos, gana la IA
            winner = 1;
            break;
        } 
        random = curand_uniform(&state) * movimientos->length;
        player_move = movimientos->listaMovimientos[random]; //Seleccion aleatoria de movimiento 
        execute_movement(local_board, N, player_move, &n_fichas_IA);  

        //Revisión de win condition 
        winner = win(local_board,N);
        if (winner != -1) break;
        turno_jugador = (turno_jugador % 2) + 1; 
        
            
        //Turno simulado de la IA
        movimientos = generarMovimientos(local_board, N, n_fichas_IA, turno_jugador, movimientos);
        if (movimientos->length == 0){
            winner = 0;
            break;
        } 
        random = curand_uniform(&state) * movimientos->length;
        IA_move = movimientos->listaMovimientos[random];
        execute_movement(local_board, N, IA_move, &n_fichas_player); 

        turno_jugador = (turno_jugador % 2) + 1;

        //Revisión de win condition 
        winner = win(local_board,N);
        if (winner != -1) break;
        iter++;
            
    }
    delete[] local_board;
    delete[] movimientos->listaMovimientos;
    delete movimientos;
    atomicAdd(evaluacion_total, winner);
}



/* ----   Codigo Principal ---- */
 

int main(int argc, char** argv) {

    // Variables que trabajaremos 
    int N = 12;
    int* board = new int[N*N];
    int n_fichas_player = 0;
    int n_fichas_IA = 0;
    char letras[] = {'A','B','C','D','E','F','G','H','K','L','M','N'};
    srand(time(NULL));
    float dt;
	int bs = 256;
	int gs = 4;
    
    //Construccion de tablero inicial
    build_board(board, N, &n_fichas_player, &n_fichas_IA);

    // Juego version CPU, IA random
    bool flag_finalizado = false;
    int turno_jugador = 1; //turno_jugador 1 es del jugador
    Movimientos* movimientos = new Movimientos;
    movimientos->length = 0;
    movimientos->listaMovimientos = new Move[2*N]; //Cantidad de movimientos es acotada
    Move player_move;
    Move IA_move;
    while(!flag_finalizado){
        //Turno del jugador
        system("clear");
        printBoard(board, N);
        movimientos = generarMovimientos(board, N, n_fichas_player, turno_jugador, movimientos);
        if (movimientos->length == 0){
            printBoard(board, N);
            printf("Ha ganado la Inteligencia Articial. La era del hombre ha llegado a su fin");
            flag_finalizado = true;
        } 
        player_move = player_select_move(movimientos, N);
        execute_movement(board, N, player_move, &n_fichas_IA);  

        //Turno de la IA
        turno_jugador = (turno_jugador % 2) + 1; 
        movimientos = generarMovimientos(board, N, n_fichas_IA, turno_jugador, movimientos);
        if (movimientos->length == 0){
            printBoard(board, N);
            printf("Ha ganado el jugador humano, venciendo a Skynet.");
            flag_finalizado = true;
        } 
        //Simulamos para cada movimiento
        int indice_maximo = 0;
        float eval_maxima = 0.;
        float* evaluacion = new float; 
        float* evaluacionGPU;
        cudaMalloc((void**)&evaluacionGPU, sizeof(float));
        int* boardGPU;
        cudaMalloc((void**)&boardGPU, N * N * sizeof(int));
        cudaMemcpy(boardGPU, board, N * N * sizeof(int), cudaMemcpyHostToDevice);
        for(int i = 0; i < movimientos->length; i++){
            *evaluacion = 0; 
            int start_position =  movimientos->listaMovimientos[i].start_position;
            int end_position =  movimientos->listaMovimientos[i].end_position;
            int kill = movimientos->listaMovimientos[i].kill;

            cudaMemcpy(evaluacionGPU,evaluacion, sizeof(float), cudaMemcpyHostToDevice);
            kernel << <gs, bs >> > (boardGPU, N, start_position, end_position, kill, n_fichas_player, n_fichas_IA, evaluacionGPU);
            cudaMemcpy(evaluacion, evaluacionGPU, sizeof(float), cudaMemcpyDeviceToHost); //Copia valor total
            
            printf("(%c%d,",letras[movimientos->listaMovimientos[i].start_position / N ], movimientos->listaMovimientos[i].start_position % N);
            printf("%c%d)",letras[movimientos->listaMovimientos[i].end_position / N ],movimientos->listaMovimientos[i].end_position % N);
            *evaluacion = (*evaluacion/(bs*gs)) * 100;
            printf("Evaluacion : %2.f%c\n",*evaluacion, '%');
            if (*evaluacion > eval_maxima){
                indice_maximo = i;
                eval_maxima = *evaluacion;
            }
        } 
        system("pause");
        IA_move = movimientos->listaMovimientos[indice_maximo];
        execute_movement(board, N, IA_move, &n_fichas_player);
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
    cudaEvent_t e1, e2;
    cudaEventCreate(&e1);
    cudaEventCreate(&e2);
    cudaEventRecord(e1);
   

    cudaEventRecord(e2);
    cudaEventSynchronize(e2);
    cudaEventElapsedTime(&dt, e1, e2);
    std::cout << "Tiempo GPU Sin Streams: " << dt << " [ms]" << std::endl;

	cudaFree(AinGPU); cudaFree(AoutGPU);
	delete[] Ain;
    */
    
}