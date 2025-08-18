

!!! This set of exercises aims at showing some basic OpenMP directives and how
!!! they affect the order (and correctness) of execution

program part1
  use omp_lib
  use, intrinsic :: iso_c_binding
  implicit none
  integer :: i, j, tid, n
  integer, dimension(:), allocatable :: buffer
  double precision rand
  character(10) :: time
  character(8) :: date

  interface
     subroutine usleep(u) bind(c)
       use, intrinsic :: iso_c_binding
       integer(kind=c_long), value :: u
     end subroutine usleep
  end interface

  interface
     integer(c_int) function srand(s) &
          bind(c, name='srand')
       use, intrinsic :: iso_c_binding
       integer(kind=c_int), value :: s
     end function srand
  end interface

#if (EXAMPLE == 1)
  write(*,"(//a/)") "   ----- Exercise 1 ------"

!!! This exercise tries to illustrate a simple parallel OpenMP
!!! program.  Run it several times. At some occasions the printed
!!! output is "wrong". Why is that? Correct the program so that it is
!!! "correct"


!$omp parallel private(i, j)

  do i = 1, 1000
     do j = 1, 1000
        tid = omp_get_thread_num()
     end do
  end do

  print *," Thread ", omp_get_thread_num(),": My value of tid (thread id) is ", tid

!$omp end parallel

  write(*,"(/a/)") "   ----- End of exercise 1 ------"
#endif

#if (EXAMPLE == 2)
  write(*,"(//a/)") "   ----- Exercise 2 ------"

!!! This exercise illustrates some of the data-sharing clauses in
!!! OpenMP. Run the program, is the output correct? Try to make the
!!! program print the correct value for n for both  parallel sections

n = 10;

!$omp parallel private(n)

n = n + omp_get_thread_num()
print *,"Thread ", omp_get_thread_num(), ": My value of n is ", n

!$omp end parallel

j = 100000
!$omp parallel do private(n)
do i = 1,j
   n = i
end do
!$omp end parallel do
print *, "After ", j, "iterations the value of n is ", n

  write(*,"(/a/)") "   ----- End of exercise 2 ------"
#endif

#if (EXAMPLE == 3)
  write(*,"(//a/)") "   ----- Exercise 3 ------"

!!! This exercise tries to illustrate the usage of rudimentary OpenMP
!!! synchronization constructs. Try to make all the threads end at the
!!! same time

!$omp parallel private(tid, date, time)

  tid = omp_get_thread_num()
  call date_and_time(time=time, date=date)

  print *, "Thread", tid, " spawned at: ", &
       date(1:4),'-', date(5:6),'-',date(7:8), ' ' ,&
       time(1:2),':',time(3:4), ':',time(5:6)

  call usleep(int(1e6, kind=c_long))

  if (mod(tid,2) .eq. 0) then
     call usleep(int(5e6, kind=c_long))
  end if
  
  call date_and_time(time=time, date=date)
  print *, "Thread", tid, " done at: ", &
       date(1:4),'-', date(5:6),'-',date(7:8), ' ' ,&
       time(1:2),':',time(3:4),':',time(5:6)

!$omp end parallel

  write(*,"(/a/)") "   ----- End of exercise 3 ------"
#endif

end program part1
