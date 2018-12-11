#include <omp.h>
#include <stdio.h>
#include <stdlib.h>

int main(int argc, char * argv[])
{
	int nb_threads=-1;
	#pragma omp parallel
	{
		nb_threads = omp_get_num_threads();	
	}


	int size = nb_threads*16;
	int * array = (int *)malloc(sizeof(int)*size);
	int i;
	for(i=0; i<size; i++) array[i] = i+1;

	int sum=0;
	int verif_sum=0;
	int tmp_sum = 0;

	for(i=0; i<size; i++) 
	{
		verif_sum += array[i];
	}
	


	//#pragma omp parallel firstprivate(tmp_sum) shared(array) reduction(+:sum)
	#pragma omp parallel for shared(array) reduction(+:sum) 
	for(int j=0; j<size; j++){
		sum+=array[j];
	}
	if(sum == verif_sum)
	{
		printf("OK! sum = verif_sum!\n");
	}
	else
	{
		printf("Error! sum != verif_sum! (sum = %d ; verif_sum = %d)\n", sum, verif_sum); 
	}
		//First way
		//int start=omp_get_thread_num()*16;
		//int stop=(omp_get_thread_num()*16)+16;
		
		//second way:
	/*	int start, stop;
		int my_rank = omp_get_thread_num();
		
		start = size /nb_threads * my_rank;
		stop = size /nb_threads * (my_rank+1);

		for(j=start; j<stop; j++){
			tmp_sum+=array[j];
		}*/
		/*//We replace with pragma for :
		#pragma omp for schedule(static)
		for(j=0; j<size; j++){
			tmp_sum+=array[j];
		}	
		
		//ou #pragma omp atomic
		#pragma omp critical
		{
			sum += tmp_sum;
		}
		*/

		//Q7:we add reduction(+:sum) at the top
		/*#pragma omp for 
		for(j=0; j<size; j++){
			tmp_sum+=array[j];
		}	
		sum += tmp_sum;*/
		//Q8: ??
	/*	for(j=0; j<nb_threads; j++)
		{		
			if(omp_get_thread_num() == j)
			{	
				printf("sum = %d \n", sum);
			}
			#pragma omp barrier
		}*/

	free(array);
	return 0;
}
