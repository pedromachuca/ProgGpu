#include <omp.h>

#include <stdlib.h>
#include <stdio.h>


int main(int argc, char * argv[])
{
	int my_rank = -1;
	int nb_threads = -1;
	
	#pragma omp parallel default(none) private(my_rank) shared(nb_threads)
	{

		my_rank = omp_get_thread_num();
		//single nowait equivalent master on peut avoir des threads arrivant au print
		//avant d'avoir executé le pragma single	
		#pragma omp single
		{
			nb_threads = omp_get_num_threads();
		}
		
		#pragma omp barrier 

		//omp_get_thread_num will print the rank of the current thread
		//omp_get_num_threads will print the total number of thread
		printf("I am thread %d (for a total of %d threads)\n", my_rank, nb_threads);
	}
	return 0;
	
}
