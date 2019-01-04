//nvcc -ccbin clang-3.8 Ex3.cu -o Ex3



#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <time.h>
#include <math.h>
#include <sys/time.h>
//#define __USE_GNU
#include <crypt.h>

#define SIZE 102400

__global__ void kernel(char *crypted, int length, int first_char, int last_char, int N){

	//int loop_size = last_char - first_char;
	//int cryptlen = strlen(crypted);
	//int max_iter = powl(loop_size, length);
	char tab[4];
	//char tab[length];
	tab[length]='\0';
	int j;

	for(j=0; j<length; j++) tab[j] = first_char;

	long double i;
	//int ret = -1;
	printf("max_iter = %lu \n", (unsigned long) max_iter);	

	for(i=0; i<max_iter; i++)
	{
		if( !strcmp( crypted, crypt( tab, "salt" ) ) ) {
			printf( "password found: %s\n", tab );
			//return i;
		}	
		tab[0]++;
		for(j=0; j<length-1; j++)
		{
			if(last_char == tab[j])
			{
				tab[j] = first_char;
				tab[j+1]++;
			}
		}		
	}	
	//return i;
}
int init(int length, int first_char, int last_char){
	
	int loop_size = last_char - first_char;
	int cryptlen = strlen(crypted);
	int max_iter = powl(loop_size, length);
	char tab[length];
	
}
/*
int search_all_1( char* crypted, int length, int first_char, int last_char ){
	int loop_size = last_char - first_char;
	int cryptlen = strlen(crypted);
	int max_iter = powl(loop_size, length);
	char tab[length];
	tab[length]='\0';
	int j;
	for(j=0; j<length; j++) tab[j] = first_char;

	long double i;
	int ret = -1;
	printf("max_iter = %lu \n", (unsigned long) max_iter);	

	for(i=0; i<max_iter; i++)
	{
		if( !strcmp( crypted, crypt( tab, "salt" ) ) ) {
			printf( "password found: %s\n", tab );
			return i;
		}	
		tab[0]++;
		for(j=0; j<length-1; j++)
		{
			if(last_char == tab[j])
			{
				tab[j] = first_char;
				tab[j+1]++;
			}
		}		
	}	
	return i;
}*/


int main( int argc, char** argv ) {
	
	char* password; 
	struct timeval t1;
	struct timeval t2; 
	int first_char, last_char;
	//int cmp;
	
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
	
	char* crypted0 = crypt( password, "salt" );
	
	char* h_crypted = (char*) malloc( (strlen(crypted0)+1)*sizeof(char) );
	char* d_crypted = (char*) malloc( (strlen(crypted0)+1)*sizeof(char) );
	
	strcpy( h_crypted, crypted0 );

	printf( "*running parameters*\n" );
	printf( " -password length:\t%d digits\n", strlen(password) );
	printf( " -digits:\t\tfrom -%c- to -%c-\n", first_char, last_char );
	printf(	" -crypted to break:\t%s\n", h_crypted );
	
	int sz_in_byte =  strlen(h_crypted)*sizeof(char);

	cudaMalloc((void**)&d_crypted, sz_in_byte);
	cudaMemcpy(d_crypted, h_crypted, sz_in_byte, cudaMemcpyHostToDevice);
	
	dim3 nBlocks;                                                                                
	dim3 nThperBlock;
	
	nBlocks.x = 16;
	nThperBlock.x = 1024;

	gettimeofday(&t1, NULL);
		
	kernel<<< nBlocks , nThperBlock >>>(d_crypted, length, first_char, last_char, SIZE);
	
	cudaDeviceSynchronize();
	cudaMemcpy(h_crypted, d_crypted, sz_in_byte, cudaMemcpyDeviceToHost);
	cudaFree(d_crypted);

	//cmp = ??
	//cmp = search_all_1( crypted, strlen( password ), first_char, last_char );
	gettimeofday(&t2, NULL);

//	double period =(double)((int)(t2.tv_sec-t1.tv_sec))+((double)(t2.tv_usec-t1.tv_usec))/1000000;  

	printf( "time: %dmin %.3fs \n", (int)((t2.tv_sec-t1.tv_sec))/60, (double)((int)(t2.tv_sec-t1.tv_sec)%60)+((double)(t2.tv_usec-t1.tv_usec))/1000000 );
	//printf( "#tries: %d\n", cmp );
	//printf( "=> efficiency: %.f tries/s\n", (double)cmp/period );

	return EXIT_SUCCESS;
}
