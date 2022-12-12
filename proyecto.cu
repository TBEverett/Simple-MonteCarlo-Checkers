#include <iostream>
#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <stdlib.h>
#include "funciones.h"
#include <curand_kernel.h>

__global__ void kernel(int* board, int N, int NTHREADS , Move movimiento, int move_number, /*int start_position, int end_position, int kill,*/ int n_fichas_player, int n_fichas_IA, float* evaluacionGPU, float* evalesGPU){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    
    if (tid < NTHREADS){
        curandState state;
        curand_init(clock64(), threadIdx.x + blockDim.x * blockIdx.x, 0, &state);

        //Creamos copia local del tablero
        int* local_board = new int[N*N];
        for(int i = 0; i < N*N; i++) local_board[i] = board[i];

        //Move movimiento = {start_position,end_position, kill};
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
        atomicAdd(&evalesGPU[move_number], winner);
        printf("evaluacion: %f\n", evalesGPU[move_number]);
   }
    
}



/* ----   Codigo Principal ---- */
 
//Agregar parametros al cmd:
// N: Tamaño de tablero
// NTHREADS: Cantidad de hebras
// Verbose: 0 o 1 por si se quiere printear las probabilidades


//Medir Tiempos

int main(int argc, char** argv) { 

    if (argc != 5){
        printf("Porfavor ingrese 4 parametros:\n N:(>=8) NTHREADS(>0) Verbose(0|1) CPUorGPU(0|1)");
    }

    //int N = atoi(argv[1]);
    int N =8;
    //int NTHREADS = atoi(argv[2]);
    int NTHREADS = 100;
    //int verbose = atoi(argv[3]);
    int verbose = 1;
    //int CPUorGPU = atoi(argv[4]); //0 o 1 para CPU o GPU respectivamente
    int CPUorGPU = 1;
    
    int bs = 256;
    int gs = (int)ceil((float) NTHREADS / bs);

    printf("%d %d\n", gs,bs);

    // Variables que trabajaremos 
    int* board = new int[N*N];
    int n_fichas_player = 0;
    int n_fichas_IA = 0;
    char letras[] = {'A','B','C','D','E','F','G','H','K','L','M','N'};
    srand(time(NULL));
    float time = 0;
    clock_t t1, t2;
    
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
        printf("------Turno del jugador------\n");
        printBoard(board, N);
        movimientos = generarMovimientos(board, N, n_fichas_player, turno_jugador, movimientos);
        if (movimientos->length == 0){
            printBoard(board, N);
            printf("Ha ganado la Inteligencia Articial. La era del hombre ha llegado a su fin");
            flag_finalizado = true;
        } 
        player_move = player_select_move(movimientos, N);
        execute_movement(board, N, player_move, &n_fichas_IA); 
        system("clear");
        

        //Turno de la IA
        printf("------Turno de la IA------\n");
        printBoard(board, N);
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
        
       /* GPU MODE */
        if (CPUorGPU == 1){
            
            float* evalesCPU = new float[movimientos->length];
            for(int i = 0; i < movimientos->length; i++ ) evalesCPU[i] = 0;  

            float* evalesGPU;
            cudaMalloc((void**)&evalesGPU, movimientos->length * sizeof(float));
            
            float* evaluacionGPU;
            cudaMalloc((void**)&evaluacionGPU, sizeof(float));

            int* boardGPU;
            cudaMalloc((void**)&boardGPU, N * N * sizeof(int));
            cudaMemcpy(boardGPU, board, N * N * sizeof(int), cudaMemcpyHostToDevice);

            cudaEvent_t ct1, ct2;
            const int nstreams = 2;
            cudaStream_t streams[nstreams];
            int streamsize = movimientos->length/nstreams;

            
            
            for(int i = 0; i < streamsize  ; i++){             
                for (int j = 0; j < nstreams; j++ ){
                    
                    *evaluacion = 0;
                    int move_number = j + i*nstreams;
                    cudaStreamCreate(&streams[j]);

                    cudaMemcpyAsync(evaluacionGPU, evaluacion,  sizeof(float), cudaMemcpyHostToDevice, streams[j]);
                    cudaMemcpyAsync(evalesGPU, evalesCPU,    movimientos->length * sizeof(float), cudaMemcpyHostToDevice, streams[j]);
                    kernel <<< gs, bs, 0, streams[j] >>> (boardGPU, N, NTHREADS, movimientos->listaMovimientos[move_number], move_number, /*start_position, end_position, kill,*/ n_fichas_player, n_fichas_IA, evaluacionGPU, evalesGPU);
                    cudaMemcpyAsync(evalesCPU, evalesGPU,  movimientos->length  * sizeof(float), cudaMemcpyDeviceToHost, streams[j]);
                   
                } 

                cudaDeviceSynchronize();

                //float ms = 1000.0 * (float)(t2 - t1) / CLOCKS_PER_SEC;
                //time += ms;
                
            }

            if(movimientos->length%nstreams != 0){
                *evaluacion = 0;
                int move_number = (movimientos->length)-1;
                cudaMemcpy(evaluacionGPU, evaluacion, sizeof(float), cudaMemcpyHostToDevice);
                cudaMemcpy(evalesGPU, evalesCPU, movimientos->length * sizeof(float), cudaMemcpyHostToDevice);
                kernel <<< gs, bs>>> (boardGPU, N, NTHREADS, movimientos->listaMovimientos[move_number],  move_number, /* start_position, end_position, kill,*/ n_fichas_player, n_fichas_IA, evaluacionGPU, evalesGPU);
                cudaMemcpy(evalesCPU, evalesGPU, movimientos->length * sizeof(int), cudaMemcpyDeviceToHost);
            }

            

            for (int i = 0; i <  movimientos->length ; i++){
               if (evalesCPU[i] > eval_maxima){
                    indice_maximo = i;
                    eval_maxima = evalesCPU[i];
                }
                if (verbose == 1){
                    printf("(%c%d,",letras[movimientos->listaMovimientos[i].start_position / N ], movimientos->listaMovimientos[i].start_position % N);
                    printf("%c%d) ",letras[movimientos->listaMovimientos[i].end_position / N ],movimientos->listaMovimientos[i].end_position % N);
                    printf("Evaluacion : %2.f %c\n", (evalesCPU[i]/ NTHREADS) * 100 , '%');
                    
                 } 
            }

            cudaFree(evaluacionGPU); cudaFree(boardGPU); cudaFree(evalesGPU); 
            delete[] evaluacion; delete[] evalesCPU;
            
        }

        
        
        /* CPU MODE */
        else if (CPUorGPU == 0) {
            for(int i = 0; i < movimientos->length; i++){
                *evaluacion = 0; 
                t1 = clock();
                for(int j = 0; j < NTHREADS; j++) *evaluacion += MonteCarloSimulation(board, N, movimientos->listaMovimientos[i], n_fichas_player, n_fichas_IA);
                t2 = clock();
                float ms = 1000.0 * (float)(t2 - t1) / CLOCKS_PER_SEC;
                time += ms;

                *evaluacion = (*evaluacion/(NTHREADS)) * 100;
                
                if (*evaluacion > eval_maxima){
                    indice_maximo = i;
                    eval_maxima = *evaluacion;
                }

                 if (verbose == 1){
                    printf("(%c%d,",letras[movimientos->listaMovimientos[i].start_position / N ], movimientos->listaMovimientos[i].start_position % N);
                    printf("%c%d) ",letras[movimientos->listaMovimientos[i].end_position / N ],movimientos->listaMovimientos[i].end_position % N);
                    printf("Evaluacion : %2.f%c\n",*evaluacion, '%');
                 }
                
             }
             delete[] evaluacion;
        }

        if (verbose == 1) system("pause");

         
        /* IA ejecuta movimiento */
        IA_move = movimientos->listaMovimientos[indice_maximo];
        execute_movement(board, N, IA_move, &n_fichas_player);
        turno_jugador = (turno_jugador % 2) + 1;

        //Revisión de win condition 
        if (win(board,N) == 0){
            printf("Ha ganado el jugador humano, venciendo a Skynet.\n");
            flag_finalizado = true;
            
        }
        else if (win(board,N) == 1){
            printf("Ha ganado la Inteligencia Articial. La era del hombre ha llegado a su fin.\n");
            flag_finalizado = true;
        }
    }
    
    if (CPUorGPU == 0) printf("Tiempo de computo medido por CPU fue: %f [ms]\n", time);
    else printf("Tiempo de computo medido por GPU fue: %f [ms]\n", time);
      
}