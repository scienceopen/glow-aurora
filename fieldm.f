C Subroutine FIELDM
C
C This subroutine was excerpted from the International Reference
C Ionosphere package by Stan Solomon, 6/88.  Its original name was
C FIELDG which was changed to avoid any naming conflict when used at
C the same time as IRI.  Labeled common /CONST/ which contained only the
C degree/radian conversion factor UMR was changed to a data statement.
C
C THIS IS A SPECIAL VERSION OF THE POGO 68/10 MAGNETIC FIELD
C LEGENDRE MODEL. TRANSFORMATION COEFF. G(144) VALID FOR 1973.
C INPUT: DLAT, DLONG=GEOGRAPHIC COORDINATES/DEG.(-90/90,0/360),
C        ALT=ALTITUDE/KM.
C OUTPUT: F TOTAL FIELD (GAUSS), Z DOWNWARD VERTICAL COMPONENT
C        X,Y COMPONENTS IN THE EQUATORIAL PLANE (X TO ZERO LONGITUDE).
C        DIP INCLINATION ANGLE(DEGREE). SMODIP RAWER'S MODFIED DIP.
C SHEIK,1977.
C
      SUBROUTINE FIELDM(DLAT,DLONG,ALT,X,Y,Z,F,DIP,DEC,SMODIP)
      implicit none
      real,intent(in) :: dlat,dlong,alt
      real,intent(out):: x,y,z,f,dip,dec,smodip

      real H(144),XI(3),G(144),FEL1(72),FEL2(72), umr,brh0,cp,ct,d,f1,
     & rho,rlat,rlong,rq,s,sp,st,x1,xt,xxx,y1,yyy,z1,zzz
      integer i,ih,ihmax,il,imax,last,m,nmax,k


      DATA UMR/.0174532952/
      DATA FEL1/0.0, 0.1506723,0.0101742, -0.0286519, 0.0092606,
     & -0.0130846, 0.0089594, -0.0136808,-0.0001508, -0.0093977,
     & 0.0130650, 0.0020520, -0.0121956, -0.0023451, -0.0208555,
     & 0.0068416,-0.0142659, -0.0093322, -0.0021364, -0.0078910,
     & 0.0045586,  0.0128904, -0.0002951, -0.0237245,0.0289493,
     & 0.0074605, -0.0105741, -0.0005116, -0.0105732, -0.0058542,
     &0.0033268, 0.0078164,0.0211234, 0.0099309, 0.0362792,
     &-0.0201070,-0.0046350,-0.0058722,0.0011147,-0.0013949,
     & -0.0108838,  0.0322263, -0.0147390,  0.0031247, 0.0111986,
     & -0.0109394,0.0058112,  0.2739046, -0.0155682, -0.0253272,
     &  0.0163782, 0.0205730,  0.0022081, 0.0112749,-0.0098427,
     & 0.0072705, 0.0195189, -0.0081132, -0.0071889, -0.0579970,
     & -0.0856642, 0.1884260,-0.7391512, 0.1210288, -0.0241888,
     & -0.0052464, -0.0096312, -0.0044834, 0.0201764,  0.0258343,
     &0.0083033,  0.0077187/
      DATA FEL2/0.0586055,0.0102236,-0.0396107,
     & -0.0167860, -0.2019911, -0.5810815,0.0379916,  3.7508268,
     & 1.8133030, -0.0564250, -0.0557352, 0.1335347, -0.0142641,
     & -0.1024618,0.0970994, -0.0751830,-0.1274948, 0.0402073,
     &  0.0386290, 0.1883088,  0.1838960, -0.7848989,0.7591817,
     & -0.9302389,-0.8560960, 0.6633250, -4.6363869, -13.2599277,
     & 0.1002136,  0.0855714,-0.0991981, -0.0765378,-0.0455264,
     &  0.1169326, -0.2604067, 0.1800076, -0.2223685, -0.6347679,
     &0.5334222, -0.3459502,-0.1573697,  0.8589464, 1.7815990,
     &-6.3347645, -3.1513653, -9.9927750,13.3327637, -35.4897308,
     &37.3466339, -0.5257398,  0.0571474, -0.5421217,  0.2404770,
     & -0.1747774,-0.3433644, 0.4829708,0.3935944, 0.4885033,
     &  0.8488121, -0.7640999, -1.8884945, 3.2930784,-7.3497229,
     & 0.1672821,-0.2306652, 10.5782146, 12.6031065, 8.6579742,
     & 215.5209961, -27.1419220,22.3405762,1108.6394043/
      K=0
      DO 10 I=1,72
      K=K+1
      G(K)=FEL1(I)
 10   G(72+K)=FEL2(I)
      RLAT=DLAT*UMR
      CT=SIN(RLAT)
      ST=COS(RLAT)
      NMAX=11
      D=SQRT(40680925.0-272336.0*CT*CT)
      RLONG=DLONG*UMR
      CP=COS(RLONG)
      SP=SIN(RLONG)
      ZZZ=(ALT+40408589.0/D)*CT/6371.2
      RHO=(ALT+40680925.0/D)*ST/6371.2
      XXX=RHO*CP
      YYY=RHO*SP
      RQ=1.0/(XXX*XXX+YYY*YYY+ZZZ*ZZZ)
      XI(1)=XXX*RQ
      XI(2)=YYY*RQ
      XI(3)=ZZZ*RQ
      IHMAX=NMAX*NMAX+1
      LAST=IHMAX+NMAX+NMAX
      IMAX=NMAX+NMAX-1
      DO I=IHMAX,LAST
        H(I)=G(I)
      End Do
      DO 200 K=1,3,2
      I=IMAX
      IH=IHMAX
 300  IL=IH-I
      F1=2./(I-K+2.)
      X1=XI(1)*F1
      Y1=XI(2)*F1
      Z1=XI(3)*(F1+F1)
      I=I-2
      IF((I-1).LT.0) GOTO 400
      IF((I-1).EQ.0) GOTO 500
      DO M=3,I,2
          H(IL+M+1)=G(IL+M+1)+Z1*H(IH+M+1)+X1*(H(IH+M+3)-H(IH+M-1))-
     &  Y1*(H(IH+M+2)+H(IH+M-2))
          H(IL+M)=G(IL+M)+Z1*H(IH+M)+X1*(H(IH+M+2)-H(IH+M-2))+
     &  Y1*(H(IH+M+3)+H(IH+M-1))
      End Do
 500  H(IL+2)=G(IL+2)+Z1*H(IH+2)+X1*H(IH+4)-Y1*(H(IH+3)+H(IH))
      H(IL+1)=G(IL+1)+Z1*H(IH+1)+Y1*H(IH+4)+X1*(H(IH+3)-H(IH))
 400  H(IL)=G(IL)+Z1*H(IH)+2.0*(X1*H(IH+1)+Y1*H(IH+2))
 700  IH=IL
      IF(I.GE.K) GOTO 300
 200  CONTINUE
      S=0.5*H(1)+2.0*(H(2)*XI(3)+H(3)*XI(1)+H(4)*XI(2))
      XT=(RQ+RQ)*SQRT(RQ)
      X=XT*(H(3)-S*XXX)
      Y=XT*(H(4)-S*YYY)
      Z=XT*(H(2)-S*ZZZ)
      F=SQRT(X*X+Y*Y+Z*Z)
      BRH0=Y*SP+X*CP
      Y=Y*CP-X*SP
      X=Z*ST-BRH0*CT
      Z=-Z*CT-BRH0*ST
      DIP=ASIN(Z/F)
      DEC=ASIN(Y/SQRT(X*X+Y*Y))
      SMODIP=ASIN(DIP/SQRT(DIP*DIP+ST))
      DIP=DIP/UMR
      DEC=DEC/UMR
      SMODIP=SMODIP/UMR
      END SUBROUTINE FIELDM
