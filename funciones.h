
#include <stdio.h>
#include <stdlib.h>
#include <iostream>
using namespace std;

struct Move{
    int start_position;
    int end_position;
    int kill;
};

struct Movimientos{
    Move* listaMovimientos;
    int length; 
};


void build_board(int* board, int N, int *n_fichas_player, int*n_fichas_rival){ 
    int filas_con_fichas = (N-2)/2;
    for (int i = 0; i < N*N; i++){
        board[i] = 0;
        if (i/N < filas_con_fichas){
            if ((i/N)%2){
                if (!(i%2)){
                    *n_fichas_rival += 1;
                    board[i] = 2;
                } 
            }
            else{
                if (i%2){
                    *n_fichas_rival += 1;
                    board[i] = 2;
                } 
            } 
        }
        else if (i/N > filas_con_fichas + 1){
            if (!(i/N%2)){
                if (i%2){
                    board[i] = 1;
                    *n_fichas_player += 1;
                } 
            }
            else{
                if (!(i%2)){
                    board[i] = 1;
                    *n_fichas_player += 1;
                }
            } 
        }
    }
}

void printBoard(int* board, int N){
    char letras[] = {'A','B','C','D','E','F','G','H','K','L','M','N'};
    cout << "   ";
    for (int i = 0; i < N; i++){
        cout << i << " ";  
    }
    cout << endl;
    for (int j = 0; j < N; j++){
        cout << letras[j] << "| ";
        for(int i = 0; i < N; i++){
            if (board[i + j*N] == 0) cout << "- ";
            else if(board[i + j*N] == 1) cout << 'O' << " ";
            else if(board[i + j*N] == 2) cout << 'X' << " ";
        }
        cout << endl;
    }
}

//Funcion que retorna ganador
__host__ __device__ float win(int *board, int N){
    for(int i = 0; i < N; i++){
       for(int j = 0; j < N; j++){
            if (board[i*N + j] == 2){
                if(i == (N - 1)) 
                    return 1.; //Retorna 1 si gana la IA
            }   
            else if (board[i*N + j] == 1) {
                if(i == 0) 
                return 0.; //Retorna 0 si pierde la IA
            }    
        }
    }
    return -1.;  
}



//Funcion que permite al jugador escoger su movimiento
Move player_select_move(Movimientos* movimientos, int N){
    char letras[] = {'A','B','C','D','E','F','G','H','K','L','M','N'};
    cout << "Movimientos que puede realizar: " << endl;
    for(int i = 0; i < movimientos->length; i++){
        printf("%d: ", i+1);
        printf("(%c%d,", letras[movimientos->listaMovimientos[i].start_position / N] ,movimientos->listaMovimientos[i].start_position % N);
        printf("%c%d)\n",letras[movimientos->listaMovimientos[i].end_position / N] ,movimientos->listaMovimientos[i].end_position % N);
    }
    int eleccion;
    printf("Ingrese su eleccion: ");
    scanf("%d",&eleccion);
    if (eleccion == 0) exit(1); //Para escapar del programa puede hacer un movimiento 0
    return {movimientos->listaMovimientos[eleccion-1].start_position,movimientos->listaMovimientos[eleccion-1].end_position,movimientos->listaMovimientos[eleccion-1].kill};
}

//Función que ejecuta un movimiento sobre el tablero. Asume que el movimiento siempre es factible.
__host__ __device__ void execute_movement(int* &board, int N, Move movimiento, int* n_fichas){
    board[movimiento.end_position] = board[movimiento.start_position];
    board[movimiento.start_position] = 0;
    if (movimiento.kill != -1){
        board[movimiento.kill] = 0;
        *n_fichas -= 1;
    }
}


//Función que retorna una lista con movimientos
__host__ __device__ Movimientos* generarMovimientos(int* board, int N, int n_fichas, int ficha_aliada, Movimientos* movimientos){ //n_fichas (de 1 jugador) nos servirá para dejar de buscar cuando hayamos procesado todas las fichas
    int colum;

    int aux_numero_fichas = n_fichas; //Acotamos la cantidad de movimientos (cantidad de fichas * 2)
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
                else if ((board[i + 1 + N*direccion_mov] == ficha_rival) && (i + 2 + 2*N*direccion_mov > 0) ){
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
                else if ((board[i - 1 + N * direccion_mov] == ficha_rival) && (i - 2 + 2*N*direccion_mov > 0) ){
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
                else if ((board[i - 1 + N*direccion_mov] == ficha_rival) && (i - 2 + 2*N*direccion_mov> 0) && colum > 1){
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
                else if ((board[i + 1 + N*direccion_mov] == ficha_rival) && (i + 2 + 2*N*direccion_mov> 0) && colum < N-2){
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

//Single Threaded Monte Carlo for Checkers
/* 
float MonteCarloSimulation(int* board,int N,Move movimiento, int n_fichas_player, int n_fichas_IA){
  
    //Creamos copia local del tablero
    int* local_board = new int[N*N];
    for(int i = 0; i < N*N; i++) local_board[i] = board[i];

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
    while(true){
        
        //Turno simulado del jugador
        movimientos = generarMovimientos(local_board, N, n_fichas_player, turno_jugador, movimientos);
        if (movimientos->length == 0) return 1; //Si jugador se queda sin movimientos, gana la IA
        int random = rand() % movimientos->length;
        player_move = movimientos->listaMovimientos[random]; //Seleccion aleatoria de movimiento 
        execute_movement(local_board, N, player_move, &n_fichas_IA);  

        //Revisión de win condition 
        winner = win(local_board,N);
        if (winner != -1) break;
        turno_jugador = (turno_jugador % 2) + 1; 
       
        
        //Turno simulado de la IA
        movimientos = generarMovimientos(local_board, N, n_fichas_IA, turno_jugador, movimientos);
        if (movimientos->length == 0) return -1; 
        IA_move = movimientos->listaMovimientos[rand() % movimientos->length];
        execute_movement(local_board, N, IA_move, &n_fichas_player); 

        turno_jugador = (turno_jugador % 2) + 1;

        //Revisión de win condition 
        winner = win(local_board,N);
        if (winner != -1) break;
        iter++;
        
    }
    delete[] local_board;
    return winner;
}
*/