C Subroutine callable by f2py Python
C
C Stan Solomon, 4/05, 12/14
C
C This software is part of the GLOW model.  Use is governed by the Open Source
C Academic Research License Agreement contained in the file glowlicense.txt.
C
C For more information see the file glow.txt
C
C For definitions of common block /CGLOW/, see subroutine GLOW
C
C Other definitions:
C F107P   Solar 10.7 cm flux for previous day
C AP      Ap index of geomagnetic activity
C Z       altitude array, km
C XNO     default values for NO concentration, cm-3
C
C Array dimensions:
C JMAX    number of altitude levels
C NBINS   number of energetic electron energy bins
C LMAX    number of wavelength intervals for solar flux
C NMAJ    number of major species
C NEX     number of ionized/excited species
C NW      number of airglow emission wavelengths
C NC      number of component production terms for each emission
C NST     number of states produced by photoionization/dissociation
C NEI     number of states produced by electron impact
C NF      number of types of auroral fluxes
C
      SUBROUTINE AURORA(Z,Pyion,Pyecalc,Pypi,Pysi,Pyisr,
     &                  idate_, ut_, glat_, glong_, f107a_, f107_,
     &                  PyPhitop)

!      use cglow,only: jmax,NMAJ,NEX,NW,NC,NST,NEI,NF,nbins,lmax,PI
      implicit none
      include 'cglow.h'

      Integer, Intent(In) :: idate_
      Real,Intent(In) :: Z(JMAX),ut_, glat_, glong_, f107a_, f107_,
     &                  PyPhitop(nbins,3)
! it's 3, not nmaj
      Real, Intent(Out)  :: Pyion(JMAX,11), Pyisr(JMAX,nmaj),
     & Pyecalc(jmax),Pypi(jmax),Pysi(jmax)

      real  TPI(NMAJ),dipd,szad,totpi,totsi
      integer i,j200,ns,j

      integer IDATE, ISCALE, JLOCAL, KCHEM, IERR,
     & IIMAXX(NBINS)

      real UT, GLAT, GLONG,
     >    F107, F107A, hlybr, FEXVIR, HLYA, HEIEW, XUVFAC,
     >    ZZ(JMAX), ZO(JMAX), ZN2(JMAX), ZO2(JMAX), ZNO(JMAX),
     >    ZNS(JMAX), ZND(JMAX), ZRHO(JMAX), ZE(JMAX),
     >    ZTN(JMAX), ZTI(JMAX), ZTE(JMAX),
     >    PHITOP(NBINS), EFLUX(NF), EZERO(NF),
     >    SZA, DIP, EFRAC,
     >    ZMAJ(NMAJ,JMAX), ZCOL(NMAJ,JMAX),
     >    WAVE1(LMAX), WAVE2(LMAX), SFLUX(LMAX),
     >    ENER(NBINS), DEL(NBINS),
     >    PESPEC(NBINS,JMAX), SESPEC(NBINS,JMAX),
     >    PHOTOI(NST,NMAJ,JMAX), PHOTOD(NST,NMAJ,JMAX), PHONO(NST,JMAX),
     >    QTI(JMAX), AURI(NMAJ,JMAX), PIA(NMAJ,JMAX), SION(NMAJ,JMAX),
     >    UFLX(NBINS,JMAX), DFLX(NBINS,JMAX), AGLW(NEI,NMAJ,JMAX),
     >    EHEAT(JMAX), TEZ(JMAX), ECALC(JMAX),
     >    ZXDEN(NEX,JMAX), ZETA(NW,JMAX), ZCETA(NC,NW,JMAX), VCB(NW),
     &   SIGS(NMAJ,NBINS), PE(NMAJ,NBINS), PIN(NMAJ,NBINS),
     >                SIGA(NMAJ,NBINS,NBINS), SEC(NMAJ,NBINS,NBINS),
     >                SIGEX(NEI,NMAJ,NBINS), SIGIX(NEI,NMAJ,NBINS)

      COMMON /CGLOW/ IDATE, UT, GLAT, GLONG, ISCALE, JLOCAL, KCHEM,
     >    F107, F107A, HLYBR, FEXVIR, HLYA, HEIEW, XUVFAC,
     >    ZZ, ZO, ZN2, ZO2, ZNO, ZNS, ZND, ZRHO, ZE,
     >    ZTN, ZTI, ZTE, PHITOP, EFLUX, EZERO, SZA, DIP, EFRAC, IERR,
     >    ZMAJ, ZCOL, WAVE1, WAVE2, SFLUX, ENER, DEL, PESPEC, SESPEC,
     >    PHOTOI, PHOTOD, PHONO, QTI, AURI, PIA, SION,
     >    UFLX, DFLX, AGLW, EHEAT, TEZ, ECALC, ZXDEN, ZETA, ZCETA, VCB

      COMMON /CXSECT/ SIGS, PE, PIN, SIGA, SEC, SIGEX, SIGIX, IIMAXX


!     Ingest Python parameters
      idate=idate_; ut=ut_; glat=glat_; glong=glong_
      f107a=f107a_; f107=f107_
      ENER = PyPhitop(:,1); DEL=PyPhitop(:,2); PHITOP=PyPhitop(:,3)

C
C
C Call GLOW to calculate ionized and excited species, airglow emission
C rates, and vertical column brightnesses:
C
      CALL GLOW
C
C
C Set electron densities to calculated values below 200 km, constant
C above:
C
      J200=0
      DO J=JMAX,1,-1
        IF (Z(J) .GT. 200.01) J200=J-1
      END DO
C
      DO J=1,JMAX
        IF (J .LE. J200) ZE(J)=ECALC(J)
        IF (J .GT. J200) ZE(J)=ECALC(J200)
        IF (ZE(J) .LT. 100.) ZE(J) = 100.
      END DO
C
C
C Call GLOW again:
C
      CALL GLOW
C
C
C Output section:
C
      SZAD = SZA * 180. / PI
      DIPD = DIP * 180. / PI

!      write (6,444) IDATE, UT, GLAT, GLONG, F107, F107A, AP
!  444 FORMAT (' Date=',i5,' UT=',f6.0,' Lat=',f5.1,' Lon=',f6.1,
!     >        ' F107=',f4.0,' F107A=',f4.0,' Ap=',f4.0)
!      WRITE (6,445) SZAD, STL, DIPD, EFRAC, IERR
!  445 FORMAT (' SZA=',F5.1,' LST=',F5.2,' Dip=',F5.1,
!     >        ' Ec=',F6.3,' Ie=',I1)
!
! Output photoionization, electron impact ionization,
! electron density, and ion densities:
!
!     write (6,690)
!  690 format ('   Z    Photoion   EIion    Ecalc     O+(2P)    ',
!    >        'O+(2D)    O+(4S)     N+         N2+       O2+       NO+')
!    >        '     O        O2         N2        NO')
      do j=1,jmax
        do i=1,nmaj
          tpi(i) = 0.
          do ns=1,nst
            tpi(i) = tpi(i) + photoi(ns,i,j)
          end do
        end do
        totpi = tpi(1) + tpi(2) + tpi(3) + phono(1,j)
        totsi = sion(1,j) + sion(2,j) + sion(3,j)

        Pypi(j) = totpi
        Pysi(j) = totsi
!       write (6,730) z(j),totpi,totsi,ecalc(j),(zxden(i,j),i=1,7)
!    >                zo(j),zo2(j),zn2(j),zno(j)
!  730   format (1x, 0p, f5.1, 1p, 14e10.2)
      end do

      Pyecalc = ecalc

      Pyion(:,1:7) = transpose(zxden(1:7,:))
      Pyion(:,8)=zo; Pyion(:,9)=zo2; Pyion(:,10)=zn2; Pyion(:,11)=zno

      Pyisr(:,1)=ZE; Pyisr(:,2)=ZTE; Pyisr(:,3)=ZTI

C
C Output selected volume emission rates and column brightnesses:
C
!      write (6,780)
!  780 format ('   z     3371   4278   5200   5577   6300',
!    >        '   7320  10400   3466   7774   8446')
!      write (6,790) (z(j), (zeta(iw,j),iw=1,10), j=1,jmax)
! 790 format (1x, f5.1, 10f7.1)
!      write (6,795)  (vcb(iw),iw=1,10)
! 795 format (' VCB:',11f7.0)
!
!
!     CALL ROUT('rt.out',EF,EZ,ITAIL,FRACO,FRACO2,FRACN2)
!
      END SUBROUTINE AURORA
