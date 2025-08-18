program add3
  use omp_lib
  use, intrinsic :: iso_fortran_env
  implicit none             
  integer, parameter :: n = 1000000000
  integer :: i
  real(kind=REAL64), allocatable, dimension(:) :: a, b, c
  real(kind=REAL64) :: tstart, tend

  allocate(a(n), b(n), c(n))

  do i = 1, n
     a(i) = 1d0 + i
     b(i) = 1d0 - i     
  end do

  tstart = omp_get_wtime();
  do i = 1, n
     c(i) = a(i) + b(i)
  end do
  tend = omp_get_wtime();
  write(*,*) 'Kernel took: ', tend - tstart

  do i = 1, 5
     write(*,*) 'c(', i, ') = ', c(i)
  end do
  write(*,*) 'c(', n, ') = ', c(n)
  
  deallocate(a, b, c)
  
end program add3

