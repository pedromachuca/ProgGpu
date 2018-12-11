#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cuda.h>
#include <sys/time.h>

#define SIZE 102400
#define MOD 102399
#define STEP 1

/* ARRAY A INITIALIZER */
void init_a(int * a)
{
    int i;
    for(i=0; i<SIZE; i++)
    {
        a[i] = 1;
    }
}

/* ARRAY B INITIALIZER */
void init_b(int * b)
{
	int i, j;

	j=0;

	for(i=0; i<SIZE-1; i++)
	{
		b[j] = i;
		j = (j+STEP)%MOD;
	}	

    b[SIZE-1] = SIZE-1;
}

/* CHECKING A VALUES */
int check_a(int * a)
{
    int i;
    int correct = 1;
	for(i=0; i<SIZE; i++)
	{
		if(a[i] != (i+1)) 
		{
         
			correct = 0;
		} 
	}	

    return correct;
}


/* CUDA FUNCTION */
__global__ void mykernel(int * a, int * b, int N)
{
	/*
	int i =blockIdx.x * blockDim.x + threadIdx.x;
    int total = (blockDim.x * gridDim.x);
    for(int j = i; j < N; j += total){
        a[b[j]] += b[j];
    }*/
	//Method prof :
	int index = threadIdx.x;
	int tmp;
	for(;index <N; index+=blockDim.x){
		tmp = b[index];
		a[tmp] = a[tmp]+tmp;
	}
}


int main(int argc, char * argv[])
{
	int sz_in_bytes = SIZE*sizeof(int);

	int * h_a = (int *)malloc(sz_in_bytes);
	int * h_b = (int *)malloc(sz_in_bytes);
	
	int *d_a, *d_b;

    init_a(h_a);
	init_b(h_b);
	
	cudaMalloc((void**)&d_a, sz_in_bytes);
	cudaMalloc((void**)&d_b, sz_in_bytes);

	cudaMemcpy(d_a, h_a, sz_in_bytes, cudaMemcpyHostToDevice);
	cudaMemcpy(d_b, h_b, sz_in_bytes, cudaMemcpyHostToDevice);

	dim3 nBlocks;
	dim3 nThperBlock;

	nBlocks.x = 1;
	
	nThperBlock.x = 1024;

	struct timeval tv_start, tv_stop;
	gettimeofday(&tv_start, NULL);

	mykernel<<< nBlocks , nThperBlock >>>(d_a, d_b, SIZE);

	cudaDeviceSynchronize();

	gettimeofday(&tv_stop, NULL);

	cudaMemcpy(h_a, d_a, sz_in_bytes, cudaMemcpyDeviceToHost);
	
	cudaFree(d_a);
	cudaFree(d_b);	

	int correct = check_a(h_a);;
	
	if(0 == correct)
	{
		printf("\n\n ******************** \n ***/!\\ ERROR /!\\ *** \n ******************** \n\n");
	}
	else
	{
		printf("\n\n ******************** \n ***** SUCCESS! ***** \n ******************** \n\n");
	}
	free(h_a);
	free(h_b);

	int nsec = tv_stop.tv_sec - tv_start.tv_sec;
	int nusec = tv_stop.tv_usec - tv_start.tv_usec;
	if(nusec <0){
		nusec = nusec + 1000000;
		nsec = nsec -1;
	}
	printf("time = %d s,%d us", nsec, nusec);
	return 1;
}
