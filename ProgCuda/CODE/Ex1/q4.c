#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
//A compare avec Ex1.cu equivalent mais ici non parallel

void kernel(double *a, double *b, double *c, int N, int dimGrid, int dimBlock)
{	
	int i, blockIdx, threadIdx;
	
	for(blockIdx=0; blockIdx<dimGrid; blockIdx++)
	{
		for(threadIdx=0; threadIdx<dimBlock; threadIdx++)
		{

			i = blockIdx * dimBlock + threadIdx; 

			if(i < N){

				c[i]=a[i]+b[i];
			}
		}
	}
}


//Partie hôte
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

    // 3-arrays allocation on device 
	d_a = (double*)malloc(sz_in_bytes);
	d_b = (double*)malloc(sz_in_bytes);
	d_c = (double*)malloc(sz_in_bytes);

    // copy on device values pointed on host by h_a and h_b
    // (the new values are pointed by d_a et d_b on device)
    memcpy(d_a, h_a, sz_in_bytes);
    memcpy(d_b, h_b, sz_in_bytes);

	int dimBlock = (64);
	int dimGrid = ((N+64 -1)/64);
	kernel(d_a, d_b, d_c, N, dimGrid, dimBlock);

    memcpy(h_c, d_c, sz_in_bytes);

    // freeing on device 
	free(d_a);
    free(d_b);
    free(d_c);

    free(h_a);
    free(h_b);
    free(h_c);

    return 0;
}
