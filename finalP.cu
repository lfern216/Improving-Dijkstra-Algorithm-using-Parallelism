#include <stdlib.h>
#include <cstdlib>
#include <stdio.h>
#include <limits.h>
#include <sys/time.h>

using namespace std;

const int NUMTHREADS = 128;
 
// Number of vertices in the graph
#define V 1024

// Find the vertex with minimum distance value, from
// the set of vertices NOT yet included in updater[]
//the result would override updater[]  

int minDistance(int shortPath[], bool updater[]) {
   // Initialize min value
   int min = INT_MAX, min_index;

   for (int x = 0; x < V; x++)
     if (updater[x] == false && shortPath[x] <= min){
         min = shortPath[x], min_index = x;
}
	//printf("%d Min: ",min_index);
   return min_index;
}//end of method


void printSolution(int shortPath[], int n) {
   printf("Vertex Distance from Source\n");
   for (int i = 0; i < V; i++)
      printf("%d \t\t %d\n", i, shortPath[i]);
} //end of method

// Funtion that implements Dijkstra's single source shortest path algorithm
// for a graph represented using adjacency matrix representation

__global__ void updateDistance(bool* updater, long* matrix, int* shortPath, int u){

int i = blockIdx.x * blockDim.x + threadIdx.x;

         // checking for the shortest distance and updating shortPath
         // Update shortPath[i] only when updater[i]!=true, there is an edge from  
         // the program will enter the if statement  as long as there are smaller nodes than the current one

         if(i<V){

    if ((!updater[i] && matrix[u*V+i] && shortPath[u] != INT_MAX && shortPath[u]+matrix[u*V+i] < shortPath[i]))
            shortPath[i] = shortPath[u] + matrix[u*V+i];

      }//end of if(big)
 
}//end of method

long* generateAdjMatrix(int count){

long* randoNumber = (long*)malloc(count*count*sizeof(long));

srand(time(NULL));

for(int i=0;i<count;i++){
	for(int j=0;j<count;j++){
		if(i !=j){
			long randomResult = rand()%2;			
			randoNumber[(i*count)+j] = randomResult;
			randoNumber[(j*count)+i]= randomResult;
		}
	}
}//end of for
	return randoNumber;
}//end of method

void printMatrix(int count, long* matrix){
//count is the size of the matrix

	for(int i=0;i<count;i++){

	         for(int j=0;j<count;j++){
	         printf("\t%3ld", matrix[(i*count)+j]);
		}
	printf("\n");
	}
}//end of method

int main() {

     //GPU
     int *d_shortPath;
     bool *d_updater;
     long* d_matrix;

     //allocate CPU variables in memory
     bool* updater = (bool *)malloc(V*sizeof(bool));
     int* shortPath = (int *)malloc(V*sizeof(int));
     long* matrix = (long *)malloc(V*V*sizeof(long));

     //generate adj matrix
     matrix = generateAdjMatrix(V);

     //print Matrix
     //printMatrix(V,matrix);

     // Initialize all distances as INFINITE(Maximum integer value) and stpSet[] as false
     for (int i = 0; i < V; i++){
        shortPath[i] = INT_MAX, updater[i] = false;
      }

     // Distance of source vertex from itself is always 0
     shortPath[0] = 0;

     //allocate GPU variables in memory
     cudaMalloc((void**) &d_updater,(V*sizeof(bool)));
     cudaMalloc((void**) &d_shortPath,(V*sizeof(int)));
     cudaMalloc((void**) &d_matrix,(V*V*sizeof(long)));

     //copying the matrix values to the GPU
     cudaMemcpy(d_matrix,matrix,V*V*sizeof(long),cudaMemcpyHostToDevice);

     //declaring the clock variables
     struct timeval start, end;

     // Find shortest path for all vertices
     for (int count = 0; count < V-1; count++) {
     // For every iteration, a minimum distance vertex is chosen from the set of vertices not yet processed
     //u is always equal to 0 in first iteration.
     int u = minDistance(shortPath, updater);	

     //start the clock
     gettimeofday(&start,NULL);
	
     // Mark the picked vertex as processed
     updater[u] = true;

     //copy the updates to GPU so we can call updateDistance 	
     cudaMemcpy(d_updater,updater,V*sizeof(bool),cudaMemcpyHostToDevice);
     cudaMemcpy(d_shortPath,shortPath,V*sizeof(int),cudaMemcpyHostToDevice);

     //call updatedistance, 1st parameter=# of blocks we have,2nd= #of threads in that block
     updateDistance<<<V,NUMTHREADS>>>(d_updater,d_matrix,d_shortPath,u);
	
     //copy the updated values to the CPU
     cudaMemcpy(shortPath,d_shortPath,V*sizeof(int),cudaMemcpyDeviceToHost);
     cudaMemcpy(updater,d_updater,V*sizeof(bool),cudaMemcpyDeviceToHost);
      
     }//end of for

     printf("\n");

     //stop clock
     gettimeofday(&end,0); //stop timing
      
     // print the constructed distance array
     printSolution(shortPath, V);

     printf("+++++++++");

     //calculate total time
     double elapsed = (end.tv_usec - start.tv_usec); // * 1000 + (end.tv_sec - start.tv_sec) * 1000;
     printf("Time elapsed: %f ms\n", elapsed);

     //free memory space
     free(updater);
     free(shortPath);
     free(matrix);

     //free GPU variables
     cudaFree(d_shortPath);
     cudaFree(d_matrix);
     cudaFree(d_updater);    
    
     return 0;
}//end of main
