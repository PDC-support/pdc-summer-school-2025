#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>
#include <omp.h>


/*
  This set of exercises aims at showing some basic OpenMP directives and how
  they affect the order (and correctness) of execution
*/

int main(int argc, char **argv) {

  int i, j, tid, n, *buffer;
  time_t ts;

  /*--------------------------------------------------------------------------*/

#if (EXAMPLE == 1)
  printf("\n   ----- Exercise 1 ------\n\n");

  /*
    This exercise tries to illustrate a simple parallel OpenMP
    program.  Run it several times. At some occasions the printed
    output is "wrong". Why is that? Correct the program so that it is
    "correct"
  */

#pragma omp parallel private(i, j)
  {
    for (i = 0; i < 1000; i++)
      for (j = 0; j < 1000; j++)
        tid = omp_get_thread_num();

    printf("Thread %d : My value of tid (thread id) is %d\n",
           omp_get_thread_num(), tid);
  }


  printf("\n   ----- End of exercise 1 ------\n\n");
#endif

  /*--------------------------------------------------------------------------*/

#if (EXAMPLE == 2)
  printf("\n   ----- Exercise 2 ------\n\n");

  /*
    This exercise illustrates some of the data-sharing clauses in
    OpenMP. Run the program, is the output correct? Try to make the
    program print the correct value for n for both  parallel sections
  */

  n = 10;
#pragma omp parallel private(n)
  {
    n += omp_get_thread_num();
    printf("Thread %d : My value of n is %d \n", omp_get_thread_num(), n);
  }

  j = 100000;
#pragma omp parallel for private(n)
  for (i = 1; i <= j; i++)
    n = i;

  printf("\nAfter %d iterations the value of n is %d \n\n", j, n);

  printf("\n   ----- End of exercise 2 ------\n\n");
#endif

  /*--------------------------------------------------------------------------*/

#if (EXAMPLE == 3)
  printf("\n   ----- Exercise 3 ------\n\n");

  /*
    This exercise tries to illustrate the usage of rudimentary OpenMP
    synchronization constructs. Try to make all the threads end at the
    same time
  */

#pragma omp parallel private(ts, tid)
  {
    tid = omp_get_thread_num();
    time(&ts);

    printf("Thread %d spawned at:\t %s", tid, ctime(&ts));
    sleep(1);
    if(tid%2 == 0)
      sleep(5);

    time(&ts);
    printf("Thread %d done at:\t %s", tid, ctime(&ts));
  }
  printf("\n   ----- End of exercise 3 ------\n\n");
#endif

  /*--------------------------------------------------------------------------*/

  return 0;
}
