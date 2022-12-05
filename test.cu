#include <iostream>
#include <cuda_runtime.h>
#include <fstream>
#include <time.h>
#include <stdlib.h>

#define BS 256

using namespace std;


__constant__ int x_const[10000];

__global__ void kernelA(int *A, int *x, int *b, int N){
    printf("hola");
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    if (tid < N*N){
        int Tid_mod_N = tid%N;
        int b_i;
        b_i = A[tid]* x[Tid_mod_N];
        atomicAdd(&b[Tid_mod_N],b_i);
    }
}

__global__ void kernelx(int *A, int *x, int *b, int N){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    if (tid < N) {
        for (int i = 0; i < N; i++){
            atomicAdd(&b[tid], A[tid + i*N] * x[tid]); //Sería mejor poner 1 atomicAdd al final, pero esto pide el enunciado
        }
    }
}

__global__ void kernelb(int *A, int *x, int *b, int N){
	int tid = threadIdx.x + blockDim.x * blockIdx.x;
	if (tid < N) {
		int sum = 0;
		for(int i = 0; i < N; i++) {
			sum += A[tid * N + i] * x[i];       
		}
		b[tid] = sum;
	}
}

__global__ void kernelRed(int *A, int *x, int *b, int N){
	int tid = threadIdx.x + blockDim.x * blockIdx.x;
  	__shared__ int Ps[BS];
	if (tid < N){	
		for (int row = 0; row < N; row++){
        Ps[threadIdx.x] = A[row * N + tid] * x[tid];
			__syncthreads();
			for (int thr = BS/2; thr >= 1; thr/=2){
				if (threadIdx.x < thr){
					Ps[threadIdx.x] +=  Ps[threadIdx.x + thr];
				}				
				__syncthreads();
			}
			if (threadIdx.x == 0) atomicAdd(&b[row],Ps[0]);
  		}	
	}
}


__global__ void kernelSM(int *A, int *x, int *b, int N){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    __shared__ int x_shared_segment[BS]; 
    int suma = 0;
    if (tid < N/BS * N){ 
        for(int segment = 0; segment <= N/BS; segment++){
            x_shared_segment[threadIdx.x] = x[(threadIdx.x) + segment*BS]; 
            __syncthreads(); //Sincronizamos para evitar leer antes de escribir por completo
            if (tid < N) {
                for(int i = 0; i < BS; i++){
                    if(segment*BS + i > N-1) break; //Check de que no nos escapemos del tamaño de A
                    suma += A[i + N * tid + segment*BS] * x_shared_segment[i]; 
                }
            }
            __syncthreads();
        }
        b[tid] = suma;    
    }
}


__global__ void kernelCM(int *A, int *b, int N){
    int tid = threadIdx.x + blockDim.x * blockIdx.x;
    if (tid < N) {
        int suma = 0;
        for(int i = 0; i < N; i++){
            suma += A[i + N * tid] * x_const[i];
        }
        b[tid] = suma;        
    }
}

/* ----   Codigo Principal ---- */
 

int main(int argc, char** argv) {
	
	float dt;
	int gs;
	//int bs = 256;


	/* Variables que trabajaremos */
	int N = pow(10,4);
	gs = (int)ceil((float) N*N / BS);



	int* A = new int[N*N];
	int* x = new int[N];
	int* b = new int[N];

    cudaEvent_t ct1, ct2;

	//Relleno de valores
	for(int i = 0; i < N; i++){
		x[i] = 1;
		b[i] = 0; //Innecesario pero así veremos un 0 si hay errores en vez de datos basura
		for(int j = 0; j < N; j++){
			A[N*i + j] = 1;
		}
	}

    //Copiamos x a memoria constante
    cudaMemcpyToSymbol(x_const, x, N*sizeof(int), 0, cudaMemcpyHostToDevice);

  

	/* -------- Momento GPU ----------- */

	

	
  /* Pasarle arreglos a GPU */
	
	int* AGPU;
	cudaMalloc((void**)&AGPU, N*N*sizeof(int));
	cudaMemcpy(AGPU, A, N*N*sizeof(int), cudaMemcpyHostToDevice);

	int* xGPU;
	cudaMalloc((void**)&xGPU, N*sizeof(int));
	cudaMemcpy(xGPU, x, N*sizeof(int), cudaMemcpyHostToDevice);

	int* bGPU;
	cudaMalloc((void**)&bGPU, N*sizeof(int));
	cudaMemcpy(bGPU, b, N*sizeof(int), cudaMemcpyHostToDevice);
	
  
    /* ------------- Kernels -------------------- */ 

  /*  Kernel A*/
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelA << <gs, BS >> > (AGPU, xGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel A: " << dt << "[ms]" << endl;
	
	
  /*  Kernel x */
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelx << <gs, BS >> > (AGPU, xGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel x: " << dt << "[ms]" << endl;

	/*  Kernel b */
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelb << <gs, BS >> > (AGPU, xGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel b: " << dt << "[ms]" << endl;

	/*  Kernel Red */
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelRed << <gs, BS >> > (AGPU, xGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel Red: " << dt << "[ms]" << endl;


	/*  Kernel CM*/
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelCM << <gs, BS >> > (AGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel CM: " << dt << "[ms]" << endl;

	/*  Kernel SM */
	cudaEventCreate(&ct1);
	cudaEventCreate(&ct2);
	cudaEventRecord(ct1);

	kernelSM << <gs, BS >> > (AGPU, xGPU, bGPU, N);
  
	cudaEventRecord(ct2);
	cudaEventSynchronize(ct2);
	cudaEventElapsedTime(&dt, ct1, ct2);

	cudaMemcpy(b, bGPU, N*sizeof(int), cudaMemcpyDeviceToHost);
	cout << "Tiempo Kernel SM: " << dt << "[ms]" << endl;

	

	
	/* Test */
	/*
    for(int i = 0; i < N; i++ ){
			if(b[i] != 10000) cout << "error" << endl;;
	}
    */

	
	/* Free */
	cudaFree(AGPU); cudaFree(xGPU); cudaFree(bGPU); 
    delete[] A; delete[] x; delete[] b;
		
	return 0;
}