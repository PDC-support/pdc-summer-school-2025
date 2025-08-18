#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(int argc, char **argv) {
                
  const int n = 1000000000;
  double *a = (double *) malloc(n * sizeof(double));
  double *b = (double *) malloc(n * sizeof(double));
  double *c = (double *) malloc(n * sizeof(double));
  double tstart, tend;

  for (int i = 0; i < n; i++) {
    a[i] = 1 + i;
    b[i] = 1 - i;
  }

  tstart = omp_get_wtime();
  for (int i = 0; i < n; i++) {
    c[i] = a[i] + b[i];
  }
  tend = omp_get_wtime();
  printf("Kernel took: %g\n", tend - tstart);
  
  for (int i = 0; i < 5; i++) {
    printf("c[%d] = %g\n", i, c[i]);
  }
  printf("c[%d] = %g\n", n-1, c[n-1]);

  free(a);
  free(b);
  free(c);
}
