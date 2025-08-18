!!! This program generates some vectors and matrices
!!! It manipulates them and finally computes some global
!!! things that are printed


program part2
  use omp_lib
  use, intrinsic :: iso_c_binding
  implicit none
  integer, parameter:: MATSIZE=900
  double precision, dimension(:,:), allocatable :: Mat_A, Mat_B, Mat_C, Mat_D
  integer, dimension(:), allocatable :: buffer
  double precision :: x, y, scal, Sum_A, Sum_B, Sum_C, Sum_D
  integer :: i, j, k, n

  double precision :: dtime, dtime2, rand

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


  allocate(Mat_A(MATSIZE, MATSIZE),Mat_B(MATSIZE, MATSIZE), &
       Mat_C(MATSIZE, MATSIZE), MAT_D(MATSIZE, MATSIZE))

#if (EXAMPLE < 4 || SERIAL)
  
  write(*,"(//a/)") "   ----- Exercise 1 ------"
!!! The code below generates three matrices. Try to think of a way in which
!!! this can be made parallel in any way. Make sure that the printed output
!!! x is correct in your parallel version


  dtime = rtc()

  x=0.35d0
  do j=1,MATSIZE
    do i=1,MATSIZE
      x=1-fraction(sin(x))
      Mat_A(i,j)=x
    end do
  end do

  x=0.68d0
  do j=1,MATSIZE
    do i=1,MATSIZE
      x=1-fraction(sin(x))
      Mat_B(i,j)=x
    end do
  end do

  x=0.24d0
  do j=1,MATSIZE
    do i=1,MATSIZE
      x=1-fraction(sin(x))
      Mat_C(i,j)=x
    end do
  end do

  dtime = rtc() - dtime
  Sum_A=check_sum(Mat_A)
  Sum_B=check_sum(Mat_B)
  Sum_C=check_sum(Mat_C)

  print *," The check sum of the matrices evaluates to:"
  print 100,"A",Sum_A
  print 100,"B",Sum_B
  print 100,"C",Sum_C
  print 110, dtime

  print 101,"The variable x evaluates to",x
100 format("Sum of matrix ",a,g25.16)
101 format(a,g37.25)
110 format("Time for the exercise: ",f9.5," seconds")
  write(*,"(/a/)") "   ----- End of exercise 1 ------"

#endif

  
#if (EXAMPLE > 1 && EXAMPLE < 3 || SERIAL)

  write(*,"(//a/)") "   ----- Exercise 2 ------"
!!! This code makes a simple attempt at computing a matrix multiply. Try
!!! to parallelize it without changing the results (more than negligible)
!!! In this exercise parallelize the outer-most loop

  dtime = rtc()
  do i=1,MATSIZE
    do j=1,MATSIZE
      scal=0.0d0
      do k=1,MATSIZE
        scal=scal+Mat_A(i,k)*Mat_B(k,j)
      end do
      Mat_D(i,j)=scal
    end do
  end do

  dtime = rtc() - dtime

  Sum_D=check_sum(Mat_D)
  print *," The check sum of the matrices evaluates to:"
  print 100,"D",Sum_D
  print 101,"The value of scal is:",scal
  print 110, dtime
  write(*,"(/a/)") "   ----- End of exercise 2 ------"
#endif

#if (EXAMPLE == 3 || SERIAL)

  write(*,"(//a/)") "   ----- Exercise 3 ------"
!!! This code makes a simple attempt at computing a matrix multiply. Try
!!! to parallelize it without changing the results (more than negligible)
!!! In this exercise parallelize the second outer-most loop

  dtime = rtc()
  do i=1,MATSIZE
    do j=1,MATSIZE
      scal=0.0d0
      do k=1,MATSIZE
        scal=scal+Mat_A(i,k)*Mat_B(k,j)
      end do
      Mat_D(i,j)=scal
    end do
  end do

  dtime = rtc() - dtime

  Sum_D=check_sum(Mat_D)
  print *," The check sum of the matrices evaluates to:"
  print 100,"D",Sum_D
  print 101,"The value of scal is:",scal
  print 110, dtime
  write(*,"(/a/)") "   ----- End of exercise 3 ------"

#endif

#if (EXAMPLE == 4)
  write(*,"(//a/)") "   ----- Exercise 4 ------"

  n = 1000
  allocate(buffer(n))

  print *, "Computing..."
  call omp_set_num_threads(8)
!$omp parallel do schedule(runtime)
  do i = 1,n
     buffer(i) = omp_get_thread_num()
     call usleep(int(srand(buffer(i))*2000, kind=c_long))
  end do
!$omp end parallel do

  print *, "Done"
  open(1, file="schedule.dat")

  do i = 1, n
     write(1, *) i, buffer(i)
  end do
  close(1)

  print *, "Now, run 'gnuplot schedule.gp' to visualize the scheduling policy"

  deallocate(buffer)

  write(*,"(/a/)") "   ----- End of exercise 4 ------"
#endif

  deallocate(Mat_A, Mat_B, Mat_C, Mat_D)

contains
  function check_sum(Mat)
    implicit none
    double precision :: check_sum
    double precision :: Mat(:,:)
    check_sum=sum(Mat)
  end function check_sum

  double precision function rtc()
  implicit none
  integer:: icnt,irate
  real, save:: scaling
  logical, save:: scale = .true.

  call system_clock(icnt,irate)

  if(scale)then
     scaling=1.0/real(irate)
     scale=.false.
  end if

  rtc = icnt * scaling

end function rtc

end program part2
