!-----------------------------------------------------------------------
!
! shwater2d.f90 solves the two dimensional shallow water equations 
! using the Lax-Friedrich's scheme
!
!-----------------------------------------------------------------------

module types
  integer, parameter :: dp = kind(0.0d0)
  integer, parameter :: sp = kind(0.0)
end module types

!-----------------------------------------------------------------------

program shwater2d
  use types
  use omp_lib
  implicit none
  
  ! This is the main routine of the program, which allocates memory 
  ! and setup all parameters for the problem.
  !
  ! You don't need to parallelize anything here!
  !
  ! However, it might be useful to change the m and n parameters 
  ! during debugging
  !
   
  integer, parameter :: cell_size = 3  
  real(kind=dp) xstart, xend, ystart, yend
  parameter (xstart = 0.0d0, ystart = 0.0d0, xend = 4d0, yend = 4d0)

  real(kind=dp), dimension(:,:,:), allocatable :: Q, nFx, nFy
  real(kind=dp), dimension(:), allocatable :: x, y
  integer i, j, ifail, m, n
  real(kind=dp) dx, dt, epsi, delta, dy, tend, tmp
  real stime
  real, external :: rtc
 

  !
  ! Use m volumes in the x-direction and n volumes in the y-direction
  !
  m = 1000
  n = 1000
  

  ! epsi      Parameter used for initial condition
  ! delta     Parameter used for initial condition
  ! dx        Distance between two volumes (x-direction)
  ! dy        Distance between two volumes (y-direction)
  ! dt        Time step
  ! tend      End time
  epsi = 2d0
  delta = 0.5
  dx = (xend - xstart) / m
  dy = (yend - ystart) / n
  dt = dx / sqrt( 9.81d0 * 5d0) 
  tend = 0.1

  !
  ! Add two ghost volumes at each side of the domain
  !
  m = m + 2
  n = n + 2

  !
  ! Allocate memory for the domain
  !
  allocate(Q(cell_size, m, n), nFx(cell_size, m, n), &
       nFy(cell_size, m, n), x(m), y(n), stat = ifail)

  if(ifail .ne. 0) then
     deallocate(Q, x, y)
     write(*,*) 'Memory exhausted'
     stop
  else
     tmp = -dx/2 + xstart
     do i=1,m
        x(i) = tmp
        tmp = tmp + dx
     end do

     tmp = -dy/2 + ystart
     do i=1,n
        y(i) = tmp
        tmp = tmp + dy
     end do     
  end if

  !
  ! Set initial Gauss hump
  !
  Q(2,:,:) = 0
  Q(3,:,:) = 0
  Q(1,:,:) = 4
  do j=2,n-1
     do i=2,m-1
        Q(1,i,j) =  4 + epsi * exp(-((x(i) - xend / 4d0)**2 + &
             (y(j) - yend / 4d0)**2)/delta**2)
     end do
  end do

  !
  ! Start solver
  !
  stime = rtc()
  call solver(Q, nFx, nFy, cell_size, m, n, tend, dx, dy, dt)
  write(*,*) 'Solver took',rtc()-stime,'sec'

  !
  ! Check if solution is finite
  ! 
  call validate(Q, cell_size, m, n)
  

  !
  ! Uncomment this line if you want visualize the result in ParaView
  !
  !call save_vtk(Q, x, y, cell_size, m, n, 'result.vtk')

  deallocate(Q, nFx, nFy, x, y)

end program shwater2d

!-----------------------------------------------------------------------

subroutine solver(Q, nFx, nFy, l, m, n, tend, dx, dy, dt)
  use types
  implicit none

  !
  ! This is the main solver routine, parallelize this. 
  !

  integer, intent(in) :: l, m, n
  real(kind=dp), intent(inout), dimension(l, m, n) :: Q, nFx, nFy
  real(kind=dp), intent(in) :: dx, dy, dt
  real(kind=dp), intent(in) :: tend
  real(kind=dp), dimension(l) :: bc_mask
  real(kind=dp) ,parameter :: g = 9.81
  real(kind=dp)  :: time
  integer k, i, j, v, steps

  bc_mask(1) = 1d0
  bc_mask(2:l) = -1d0

  steps = tend / dt
  time = 0d0

  !
  ! This is the main time stepping loop
  !
  !$omp parallel private(time)
  do k=1,steps
     
     !
     ! Apply boundary condition
     !
     !$omp do collapse(2)
     do j  = 2, n - 1
        do v = 1, l
           Q(v, 1, j) = bc_mask(v) * Q(v, 2, j)
           Q(v, m, j) = bc_mask(v) * Q(v, m-1, j)
        end do
     end do
     !$omp end do
     !$omp do collapse(2)
     do j  = 1, m
        do v = 1, l
           Q(v, j, 1) = bc_mask(v) *  Q(v, j , 2)
           Q(v, j, n) = bc_mask(v) *  Q(v, j, n-1)
        end do
     end do
     !$omp end do
     !
     ! Update all volumes with the Lax-Friedrich's scheme
     !

     !
     ! Calculate and update fluxes in the x-direction
     !
     !$omp do
     do i=2,n
                
        do j=2,m
           nFx(1,j,i) = 0.5 * ((q(2,j-1,i) + q(2,j,i)) - &
                dx/dt * (Q(1,j,i) - Q(1,j-1,i)))

           nFx(2,j,i) = 0.5 * (((q(2,j-1,i)**2 / q(1,j-1,i)) + &
                (g * q(1,j-1,i)**2) / 2d0  + &
                (q(2,j,i)**2 / q(1,j,i)) + (g * q(1,j,i)**2) / 2d0) - &
                dx/dt * (Q(2,j,i) - Q(2,j-1,i)))

           nFx(3,j,i) = 0.5 * (((q(2,j-1,i) * q(3,j-1,i)) / q(1,j-1,i) + &
                (q(2,j,i) * q(3,j,i)) / q(1,j,i)) - &
                dx/dt * (Q(3,j,i) - Q(3,j-1,i)))           
        end do
        
        do j=2,m-1
           do v = 1, l
              Q(v,j,i) = Q(v,j,i) -  dt/dx * ((nFx(v,j+1,i)  -  nFx(v,j,i)))
           end do
        end do
        
     end do
     !$omp end do

     !
     ! Calculate and update fluxes in the y-direction
     !
     !$omp do
     do i=2,m
     
        do j=2,n

           nFy(1,i,j) = 0.5 * ((Q(3,i,j-1) + Q(3,i,j)) - &
                dy/dt * (Q(1,i,j) - Q(1,i,j-1)))

           nFy(2,i,j) = 0.5 * (((q(2,i,j-1) * q(3,i,j-1)) / q(1,i,j-1) + &
                (q(2,i,j) * q(3,i,j)) / q(1,i,j)) - &
                dy/dt * (Q(2,i,j) - Q(2,i,j-1)))

           nFy(3,i,j) = 0.5 * (((q(3,i,j-1)**2 / q(1,i,j-1) ) + &
                (g * q(1,i,j-1)**2) / 2d0 + &
                (q(3,i,j)**2 / q(1,i,j) ) + (g * q(1,i,j)**2) / 2d0) - &
                dy/dt * (Q(3,i,j) - Q(3,i,j-1)))
        end do
        
        do j=2,n-1
           do v = 1, l
              Q(v,i,j) = Q(v,i,j) -  dt/dy * ((nFy(v,i,j+1)  -  nFy(v,i,j)))
           end do
        end do
        
     end do
     !$omp end do

     time = time + dt

  end do
  !$omp end parallel
end subroutine solver

!-----------------------------------------------------------------------
!
! The rest of the file contains auxiliary functions, which you don't
! need to parallelize.
!-----------------------------------------------------------------------

real function rtc()
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

!-----------------------------------------------------------------------

subroutine validate(q, l, m, n)
  use types
  use, intrinsic :: ieee_arithmetic, only: ieee_is_finite
  implicit none
  real(kind=dp), intent(in),dimension(l,m,n) :: q
  integer, intent(in) :: l, m, n
  integer i, j, k 

  do j=1,n
     do i=1,m
        do k=1,l
           if (.not. ieee_is_finite(q(k,i,j))) then  
              stop 'Invalid solution'
           end if
        end do
     end do
  end do

end subroutine validate

!-----------------------------------------------------------------------

subroutine save_vtk(Q, x, y, l, m, n, fname)
  implicit none
  integer, intent(in) :: l, m, n
  double precision, intent(in), dimension(l, m, n) :: Q
  double precision, intent(in), dimension(n) :: x
  double precision, intent(in), dimension(m) :: y
  character, intent(in) :: fname*(*)
  integer i,j
  
  open(1, file=fname)
  
  !
  ! Write vtk Datafile header
  !
  write(1,fmt='(A)') '# vtk DataFile Version 2.0'
  write(1,fmt='(A)') 'VTK'
    write(1,fmt='(A)') 'ASCII'
  write(1,fmt='(A)') 'DATASET POLYDATA'
  write(1,*)
  
  !
  ! Store water height as polydata
  !
  write(1,fmt='(A,I8,A)') 'POINTS', m*n,' double'
  do j=1,n
     do i=1,m
        write(1,fmt='(F7.5,F15.6,F17.12)') x(i), y(j), Q(1,i,j)
     end do
  end do
  write(1,*)
  
  write(1,fmt='(A,I12,I12,I12)') 'VERTICES',n,n*(m+1)
  do j=1,n
     write(1,fmt='(I12)', advance='no') m
     do i=0,m-1
        write(1,fmt='(I12)', advance='no') i+(j-1)*(m)
     end do
     write(1,*)
  end do
  
  !
  ! Store lookup table
  !
  write(1,fmt='(A,I12)') 'POINT_DATA',m*n
  write(1,fmt='(A)') 'SCALARS height double 1'
  write(1,fmt='(A)') 'LOOKUP_TABLE default'
  do j=1,n
     do i=1,m
        write(1,fmt='(F15.12)') Q(1,i,j)
     end do
  end do
  write(1,*)
  close(1)
  
end subroutine save_vtk

!-----------------------------------------------------------------------
