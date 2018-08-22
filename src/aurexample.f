C Example driver program for GLOW subroutine package.
C  aurora version
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
      Program glowprogram
       use, intrinsic :: iso_fortran_env, only : stdin=>input_unit
!      use cglow,only: jmax,nmaj,nex,nw,nc,nst,nei,nf,nbins,lmax,pi
      implicit none
      include 'cglow.h'

      real Z(JMAX),ap,f107p,ef,ec,emono,fmono
      real D(8), T(2), SW(25), OUTF(11,JMAX), OARR(30), TPI(NMAJ),dipd,
     > rz12,stl,szad,totpi,totsi
      integer i,iday,ijf,j,j200,jmag,mmdd,ns,itail,iw

      LOGICAL JF(12)
      DATA SW/25*1./

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

      ! 120 values for Z -> Jmax=120 in cglow.h
      DATA Z/     30., 31., 32., 33., 34., 35., 36., 37., 38., 39.,
     >            40., 41., 42., 43., 44., 45., 46., 47., 48., 49.,
     >            50., 51., 52., 53., 54., 55., 56., 57., 58., 59.,
     >            60., 61., 62., 63., 64., 65., 66., 67., 68., 69.,
     &            70., 71., 72., 73., 74., 75., 76., 77., 78., 79.,
     &            80., 81., 82., 83., 84., 85., 86., 87., 88., 89.,
     >            90., 91., 92., 93., 94., 95., 96., 97., 98., 99.,
     >           100.,101.,102.,103.,104.,105.,106.,107.,108.,109.,
     >           110.,111.5,113.,114.5,116.,118.,120.,122.,124.,126.,
     >           128.,130.,132.,134.,136.,138.,140.,142.,144.,146.,
     >           148.,150.,153.,156.,159.,162.,165.,168.,172.,176.,
     >           180.,185.,190.,195.,200.,205.,211.,217.,223.,230.,
     >           237.,244.,252.,260.,268.,276.,284.,292.,300.,309.,
     >           318.,327.,336.,345.,355.,365.,375.,385.,395.,406.,
     >           417.,428.,440.,453.,467.,482.,498.,515.,533.,551.,
     >           570.,590.,610.,630.,650.,670.,690.,710.,730.,750.,
     >           770.,790.,810.,830.,850.,870.,890.,910.,930.,950./

C Obtain input parameters from stdin:
      read (stdin,*) idate,ut,glat,glong,f107a, f107, f107p, ap, ef, ec
C
C
C Set other parameters and switches:
C
      JLOCAL = 0
      KCHEM = 4
      ISCALE = 1
      XUVFAC = 3.
      HLYBR = 0.
      FEXVIR = 0.
      HLYA = 0.
      HEIEW = 0.
      ITAIL = 0
      FMONO = 0.
      EMONO = 0.
C
C
C Set up energy grid:
C
      CALL EGRID (ENER, DEL)
C
C
C Generate auroral electron flux into PHITOP array:
C
      CALL MAXT (EF, EC, ENER, DEL, ITAIL, FMONO, EMONO, PHITOP)
C
C
C Calculate local solar time:
C
      STL = (UT/240.+GLONG) / 15.
      IF (STL .LT. 0.) STL = STL + 24.
      IF (STL .GT. 24.) STL = STL - 24.
C
C
C Call MSIS to get neutral densities and temperature:
C
        CALL TSELEC(SW)

        DO J=1,JMAX
          CALL GTD7(IDATE,UT,Z(J),GLAT,GLONG,STL,F107A,F107P,AP,48,D,T)
          ZO(J) = D(2)
          ! If altitude under 100km and O number density there < 1e7 cm^-3,
          ! replace O density with O2 density there
!**********************************
!very important for not getting all-NaN output below 72.50 km!!!
          IF (ZO(J) .LT. 1.E7 .AND. Z(J) .LT. 100.) ZO(J) = D(4)*1.E-7
!***********************************
          ZN2(J) = D(3)
          ZO2(J) = D(4)
          ZRHO(J) = D(6)
          ZNS(J) = D(8)
          ZTN(J) = T(2)
          if (isnan(zo(j)))  stop 'NaN in O+ density'
          if (isnan(zn2(j))) stop 'NaN in N2+ density'
          if (isnan(zo2(j))) stop 'NaN in O2+ density'
          if (isnan(ztn(j))) stop 'NaN in Tn'
        END DO
C
C
C Call SNOEMINT to obtain NO profile from the Nitric Oxide Empirical
C Model (NOEM)
C
      CALL SNOEMINT(IDATE,GLAT,GLONG,F107,AP,Z,ZTN,ZNO)
C
C
C Call International Reference Ionosphere-1990 subroutine to get
C electron density and temperature and ion temperature:
C
C NOTE: the directory specified in the call to IRI90 must be changed
C to the one where the ccirnn.asc and ursinn.asc files are.
C
      DO IJF=1,12
        JF(IJF) = .TRUE.
      END DO

      JF(5) = .FALSE.
      JF(12) = .FALSE. !no disk output for iri90
      JMAG = 0
      RZ12 = -F107A
      IDAY = IDATE - IDATE/1000*1000
      MMDD = -IDAY
      CALL IRI90(JF,JMAG,GLAT,GLONG,RZ12,MMDD,STL,Z,JMAX,
     >           'iri/',OUTF,OARR)
      DO J=1,JMAX
        ZE(J) = OUTF(1,J) / 1.E6
        IF (ZE(J) .LT. 100.) ZE(J) = 100.
        ZTI(J) = OUTF(3,J)
        IF (ZTI(J) .LT. ZTN(J)) ZTI(J) = ZTN(J)
        ZTE(J) = OUTF(4,J)
        IF (ZTE(J) .LT. ZTN(J)) ZTE(J) = ZTN(J)
        ZXDEN(3,J) = ZE(J) * OUTF(5,J)/100.
        ZXDEN(6,J) = ZE(J) * OUTF(8,J)/100.
        ZXDEN(7,J) = ZE(J) * OUTF(9,J)/100.
        if (isnan(ze(j))) stop 'NaN in Ne'
        if (isnan(zti(j)))stop 'NaN in Ti'
        if (isnan(zte(j)))stop 'NaN in Te'
      END DO
C
C
C Fill altitude array and initialize N(2D):
C
      DO J=1,JMAX
        ZZ(J)   = Z(J) * 1.E5
        ZND(J)  = 0.
      END DO
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

      write (6,444) IDATE, UT, GLAT, GLONG, F107, F107A, AP
  444 FORMAT (' Date=',i5,' UT=',f6.0,' Lat=',f5.1,' Lon=',f6.1,
     >        ' F107=',f4.0,' F107A=',f4.0,' Ap=',f4.0)
      WRITE (6,445) SZAD, STL, DIPD, EFRAC, IERR
  445 FORMAT (' SZA=',F5.1,' LST=',F5.2,' Dip=',F5.1,
     >        ' Ec=',F6.3,' Ie=',I1)
 
C Output total energy deposition,
C photoionization, electron impact ionization,
C electron density, and ion densities:
 
      write (6,690)
  690 format ('   Z      Edep    Photoion   EIion    Ecalc     ',
     >        'O+(2P)    '
     >        'O+(2D)    O+(4S)     N+         N2+       O2+       NO+')
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
        write (6,730) z(j),tez(j),totpi,totsi,ecalc(j),
     >               (zxden(i,j),i=1,7)
C    >                zo(j),zo2(j),zn2(j),zno(j)
  730   format (1x, 0p, f5.1, 1p, 14e10.2)
      end do

C
C Output selected volume emission rates and column brightnesses:
C
      write (6,780)
  780 format ('   z     3371   4278   5200   5577   6300',
     >        '   7320  10400   3466   7774   8446')
      write (6,790) (z(j), (zeta(iw,j),iw=1,10), j=1,jmax)
  790 format (1x, f5.1, 10f7.1)
      write (6,795)  (vcb(iw),iw=1,10)
  795 format (' VCB:',11f7.0)

C     CALL ROUT('rt.out',EF,EZ,ITAIL,FRACO,FRACO2,FRACN2)

      END Program
