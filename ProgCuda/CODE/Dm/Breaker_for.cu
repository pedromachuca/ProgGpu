#include <stdlib.h>
#include <sys/time.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <cuda.h>

__device__ int endLoop=0;

__device__ __host__ int get_keypair(char* tab, int length, int first_char, int last_char){

	int sum=0;

	int pow=1;
	int i=0;
	
	for(i=0; i<length; i++){
		sum+=tab[i]*pow;
		pow*=(last_char - first_char);	
	}
	return sum;
}


__host__ __device__ int check_keypairs(int crypt, int test)
{
	if(crypt == test){
		return 1;
	}
	else{
		return 0;
	}
}


__global__ void kernel( int *crypted, int length, int first_char, int last_char, double max_iter){

	int loop_size = last_char - first_char;
	
	int i =blockIdx.x * blockDim.x + threadIdx.x;
	int total = (blockDim.x * gridDim.x);	

	char *tab = (char*)malloc(sizeof(char)*(length+1));
	tab[length]='\0';
	int j;
	for(j=0; j<length; j++) tab[j] = first_char;

	int current_keypair;
	int pow=0;	

	for(int j=i; j<max_iter; j+=total){
		pow=1;
		for(int x=0; x<length; x++){
			tab[x] = ((j/pow) % loop_size) + first_char;
			pow*=loop_size;
		}
		current_keypair = get_keypair(tab, length, first_char, last_char);
		
		if( check_keypairs(*crypted, current_keypair) ) {
			printf( "password found: %s\n", tab );
			endLoop=1;
		}
		if(endLoop==1){
			j=max_iter;
		}	
	}	
}


int main( int argc, char** argv ) {
	char* password; 
	int first_char, last_char;
	float t1, t2; 
	
	//unsigned long cmp;
	
	if( argc == 1 ) {
		password = "A$4c";
		first_char = 32;
		last_char = 126;
		/* ---ASCII values---
		 * special characters: 	32 to 47
		 * numbers: 		48 to 57
		 * special characters: 	58 to 64
		 * letters uppercase: 	65 to 90
		 * special characters: 	91 to 96
		 * letters lowercase: 	97 to 122
		 * special characters: 	123 to 126
		 * */
	} else if( argc == 4 ) {
		password = argv[1];
		first_char = atoi( argv[2] );
		last_char = atoi( argv[3] );
	} else {
		printf("usage: breaker <password> <first_ch> <last_ch>\n");
		printf("default: breaker A$4c 32 126\n");
		printf("exemple to break the binary password 1101000:\n");
		printf( "breaker 1101000 48 49\n" );
		exit( 0 );
	}
	
	int length = strlen(password);	
	int sz_in_bytes = sizeof(int);

	int *h_crypted = (int *)malloc(sizeof(int));

	int crypted_to_break= get_keypair(password, length, first_char, last_char);
	
	h_crypted = &crypted_to_break;

	int *d_crypted=(int *)malloc(sizeof(int));
	
	printf( "*running parameters*\n" );
	printf( " -password length:\t%lu digits\n", strlen(password) );
	printf( " -password length:\t%s digits\n", password);
	printf( " -digits:\t\tfrom -%c- to -%c-\n", first_char, last_char );
	printf(	" -crypted to break:\t%d\n", crypted_to_break);
	
	t1 = clock();
	
	cudaMalloc((void**)&d_crypted, sz_in_bytes);
 
        cudaMemcpy(d_crypted, h_crypted, sz_in_bytes, cudaMemcpyHostToDevice);

	dim3 nBlocks;                                                                                
        dim3 nThperBlock;

	nBlocks.x = 16;
	nThperBlock.x = 1024;

	int loop_size = last_char - first_char;
	double max_iter = powl(loop_size, length);
		
	kernel<<< nBlocks , nThperBlock >>>(d_crypted, length, first_char, last_char, max_iter);
	cudaDeviceSynchronize();
	
	t2 = clock();

	cudaMemcpy(h_crypted, d_crypted, sz_in_bytes, cudaMemcpyDeviceToHost);   
        cudaFree(d_crypted);

	
	float period = (t2-t1)/CLOCKS_PER_SEC;
	if( period < 60 ){
		printf( "time: %.1fs \n", period );
	}else{
		printf( "time: %.1fmin \n", period/60 );
	}
	
	return EXIT_SUCCESS;
}

