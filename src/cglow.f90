MODULE cglow
    implicit none
    public
! This replaces glow.h:
!
! JMAX (number of vertical levels) is set to 64 for tgcm runs
! If not a tgcm run, JMAX is set in the namelist input file
!
!  integer :: JMAX
!
! These don't change:
!
!  integer,parameter :: NBINS=190
!  integer,parameter :: LMAX=123
  integer,parameter :: NMAJ=3
  integer,parameter :: NEI=10
  integer,parameter :: NEX=20
  integer,parameter :: NW=20
  integer,parameter :: NC=10
  integer,parameter :: NST=6
  integer,parameter :: NF=4

  integer, parameter :: dp = kind(1.0D0)
  integer, parameter :: sp = kind(1.0)
  real, parameter    :: pi = 4.*ATAN(1.)

  real, parameter    :: Re = 6.371e8  !radius of earh in centimeters
  real, parameter    :: G  = 978.1    !gravitational constant dynes

! Standard parameters for photoelectron or aurora runs (up to 50 keV):
      integer, PARAMETER :: JMAX=120
      integer, PARAMETER :: NBINS=190
      integer, PARAMETER :: LMAX=123
!
! Parameters for high energy aurora (up to 100 MeV):
!     integer,PARAMETER :: (JMAX=170)
!     integer,PARAMETER :: (NBINS=343)
!     integer,PARAMETER :: (LMAX=123)
END MODULE cglow
