#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#define checkCudaErrors(val)\
	fprintf(stderr, "CUDA error at %s:%d (%s) \n", __FILE__, __LINE__, cudaGetErrorString(val));

//Par rapport a la question 7 N = 1000 et nb thread = 640 
//		=>si on fait 2 x nb_thread alors 1280 threads > N peut causer bufferoverflow/seg fault

__global__ void kernel(double *a, double *b, double *c, int N)
{
    //int i = blockIdx.x * blockDim.x + threadIdx.x;
	//Q 8 :
	/*
    int i = 2*(blockIdx.x * blockDim.x + threadIdx.x);
	if(i<N-1){
		c[i] = a[i] + b[i];
		c[i+1] = a[i+1] + b[i+1];
	}*/
	//Q 8 second way :
	int i = blockIdx.x * blockDim.x + threadIdx.x;
	int totalthreads = (blockDim.x * gridDim.x);
	c[i] = a[i] + b[i];
	if(i<(N-totalthreads)){
		c[i+totalthreads] = a[i+totalthreads] + b[i+totalthreads];
	}


}

int main(int argc, char **argv)
{
    int N = 1000;
    int sz_in_bytes = N*sizeof(double);

    double *h_a, *h_b, *h_c;
    double *d_a, *d_b, *d_c;

    h_a = (double*)malloc(sz_in_bytes);
    h_b = (double*)malloc(sz_in_bytes);
    h_c = (double*)malloc(sz_in_bytes);

    // Initiate values on h_a and h_b
    for(int i = 0 ; i < N ; i++)
    {
	h_a[i] = 1./(1.+i);
	h_b[i] = (i-1.)/(i+1.);
    }

    checkCudaErrors(cudaMalloc((void**)&d_a, sz_in_bytes));
    checkCudaErrors(cudaMalloc((void**)&d_b, sz_in_bytes));
    checkCudaErrors(cudaMalloc((void**)&d_c, sz_in_bytes));

    checkCudaErrors(cudaMemcpy(d_a, h_a, sz_in_bytes, cudaMemcpyHostToDevice));
    checkCudaErrors(cudaMemcpy(d_b, h_b, sz_in_bytes, cudaMemcpyHostToDevice));

    dim3  dimBlock(64, 1, 1);
    dim3  dimGrid(10, 1, 1);
    kernel<<<dimGrid , dimBlock>>>(d_a, d_b, d_c, N);

    checkCudaErrors(cudaMemcpy(h_c, d_c, sz_in_bytes, cudaMemcpyDeviceToHost));

    checkCudaErrors(cudaFree(d_a));
    checkCudaErrors(cudaFree(d_b));
    checkCudaErrors(cudaFree(d_c));

    // Verifying
    double err = 0, norm = 0;
    for(int i = 0 ; i < N ; i++)
    {
		double err_loc = fabs(h_c[i] - (h_a[i]+h_b[i]));
		err  += err_loc;
		norm += fabs(h_c[i]);
    }
    if (err/norm < 1.e-16)
    {
		printf("SUCCESS (Relative error : %.3e)\n", err/norm);
    }
    else
    {
		printf("ERROR (Relative error : %.3e)\n", err/norm);
    }

    free(h_a);
    free(h_b);
    free(h_c);

    return 0;
}

