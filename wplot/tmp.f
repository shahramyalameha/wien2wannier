      SUBROUTINE MAIN2
      use struct
      use radgrd
      use lolog
      use loabc
      use atspdt
      use radfu
      use bessfu
      use work
      use grid
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.inc'
      CHARACTER  TITEL*80,LATTIC*4,MODE*4,SWITCH*3,IUNIT*3,ANAME*10, &
                 BNAME*10, HANDLE*4, WHPSI*5
      LOGICAL    LARGE
      COMPLEX*16 SUM
!_REAL         REAL*8,allocatable ::     CF(:)
!_COMPLEX      COMPLEX*16,allocatable :: CF(:)
      COMPLEX*16,allocatable :: COEF(:)
      real*8,allocatable :: BK(:,:)
!
!     common blocks holding input data and parameters 
      COMMON /LATT  / VUC,BR1(3,3),BR2(3,3),BR3(3,3),BR4(3,3)
      COMMON /SYM2  / IMAT(3,3,NSYM),TAU(3,NSYM),IORD
      COMPLEX*16,allocatable :: PSI(:),tot(:)
      COMPLEX*16 ALM((LMAX7+1)*(LMAX7+1),NRF), Y((LMAX7+1)*(LMAX7+1))
      COMPLEX*16 PHS,CIM
      DIMENSION  A(3),NP(3),NPO(0:3)
      real*8,allocatable ::  ROTLOC(:,:,:),atms(:,:)
      integer,allocatable :: IOP(:),nreg(:)
      DIMENSION  ROT0(3,3),R(3),FK(3)
      integer,allocatable ::  KX(:),KY(:),KZ(:)
      complex*16,allocatable :: uu(:)
      LOGICAL    REL,ORTHO,PRIM,ORTH,ISPSI,ISRE,ISIM,ISC,ISABS,ISARG, &
                 ALLKPT,ALLEIG,KFOUND,NFOUND,DEPHAS,GETABC,PUTABC, &
                 SHRMEM,WAN
!
       shrmem = .false.
       CIM=(0.d0,1.d0)
       !debug
       ISC =.false.
!
! ##################################
! # PART I : structural processing #
! ##################################
!
!     << set up the lattice >>
      READ(8,1000) TITEL
      READ(8,1010) LATTIC,NAT,MODE
      NATO=nat
      allocate ( POS(3,NATO*48),ZNUC(NATO),RMT(NATO),MULT(NATO),IATNR(NATO*48))
      allocate ( RM(NRAD,NATO),RNOT(NATO),DX(NATO),JRI(NATO) )
      allocate ( ILO(0:LOMAX, NATO),LAPW(0:LMAX7,NATO) )
      allocate ( ALO(0:LOMAX,NLOAT,NRF,NATO))
      allocate ( P(0:LMAX7,NRF,NATO),DP(0:LMAX7,NRF,NATO))
      allocate ( RRAD(NRAD,0:LMAX7,NRF,NATO))
      allocate ( RAD(NATO),IRAD(NATO))
      allocate ( ROTLOC(3,3,NATO*48),atms(3,NATO))
      allocate ( IOP(NATO*48),nreg(0:NATO*48)) 
      REL = MODE .EQ. 'RELA'
      READ(8,1020) A,ALPHA,BETA,GAMMA
      IF(ALPHA.EQ.0.0D0) ALPHA=90.0D0
      IF(BETA .EQ.0.0D0) BETA =90.0D0
      IF(GAMMA.EQ.0.0D0) GAMMA=90.0D0
      DO 10 I=LEN(TITEL),1,-1
   10 IF(TITEL(I:I).NE.' ') GOTO 11
   11 WRITE(6,2000) TITEL(1:I)
      WRITE(6,2010) LATTIC,NAT,MODE
      WRITE(6,2020) A,ALPHA,BETA,GAMMA
      CALL LATGEN(LATTIC,A,ALPHA,BETA,GAMMA,ORTHO,PRIM)
      NMT=0
      INDEX=0
      DO 20 JATOM=1,NAT
        INDEX1 = INDEX+1
        INDEX=INDEX+1
        READ(8,1030) IATNR(INDEX),(POS(I,INDEX),I=1,3),MULT(JATOM)
        IATNR(INDEX) = ABS(IATNR(INDEX))
        DO 30 MU=2,MULT(JATOM)
          INDEX=INDEX+1
          READ(8,1030) IATNR(INDEX),(POS(I,INDEX),I=1,3)
          IATNR(INDEX) = ABS(IATNR(INDEX))
   30   CONTINUE
        READ(8,1040) ANAME,JRI(JATOM),RNOT(JATOM),RMT(JATOM), &
                     ZNUC(JATOM)
        DX(JATOM) = LOG( RMT(JATOM)/RNOT(JATOM) ) / DBLE( JRI(JATOM)-1 )
        IF(JRI(JATOM).GT.NRAD) STOP 'NRAD too small'
        DO 40 I=1,JRI(JATOM)
          RM(I,JATOM) = RNOT(JATOM) * EXP( DBLE(I-1)*DX(JATOM) )
   40   CONTINUE
        RMT(JATOM) = RM(JRI(JATOM),JATOM)
        READ(8,1050) ((ROTLOC(I,J,INDEX1),I=1,3),J=1,3)
        DO 45 J=1,NMT
          IF(RMT(JATOM).EQ.RAD(J))THEN
            IRAD(JATOM) = J
            GOTO 20
          ENDIF
   45   CONTINUE
        NMT = NMT + 1
        nrmt=nmt
        RAD(NMT) = RMT(JATOM)
        IRAD(JATOM) = NMT
   20 CONTINUE
      NDAT = INDEX
      allocate ( AUG(NRAD,(LMAX7+1)*(LMAX7+1),NDat))
      !write(*,*)"debug main1"
      WRITE(6,2030)
      READ(8,1060) IORD
      IF(IORD.GT.NSYM) STOP 'NSYM too small'
      DO 50 K=1,IORD
        READ(8,1070) ((IMAT(J,I,K),J=1,3),TAU(I,K),I=1,3)
        WRITE(6,2040) K,((IMAT(J,I,K),J=1,3),TAU(I,K),I=1,3)
   50 CONTINUE
      WRITE(6,2050)
      DO 60 INDEX=1,NDAT
        DO 65 J=1,3
          R(J) = POS(1,INDEX)*BR1(1,J) + POS(2,INDEX)*BR1(2,J) &
               + POS(3,INDEX)*BR1(3,J)
   65   CONTINUE
        WRITE(6,2060) IATNR(INDEX),(POS(I,INDEX),I=1,3),(R(J),J=1,3)
   60 CONTINUE
      !write(*,*)"debug main2"
      IF(.NOT.PRIM) CALL trans(NDAT,POS,IORD,IMAT,TAU)
      !write(*,*)"debug main3"
      !write(*,*)"debug nat",nat
      !write(*,*)"debug mult",mult
      !write(*,*)"debug pos",pos
      !write(*,*)"debug iop",iop
      CALL ROTDEF(NAT,MULT,POS,IOP)
      !write(*,*)"debug main4"
!
!     << set up local rotations for all basis atoms (in Cartesian coord.) >>
      INDEX=0
      DO 130 JATOM=1,NAT
        INDEX1 = INDEX+1
!       << store ROTLOC(1.atom) before updating it >>
        DO 140 I=1,3
        DO 140 J=1,3
          ROT0(I,J) = ROTLOC(I,J,INDEX1)
  140   CONTINUE
        DO 150 MU=1,MULT(JATOM)
          INDEX = INDEX+1
          CALL LOCDEF(ROT0,IMAT(1,1,IOP(INDEX)),ROTLOC(1,1,INDEX))
  150   CONTINUE
  130 CONTINUE
      WRITE(6,2070)
      DO 160 INDEX=1,NDAT
        WRITE(6,2080) IATNR(INDEX),IOP(INDEX), &
                      ((ROTLOC(I,J,INDEX),I=1,3),J=1,3)
        IF(.NOT.ORTH(ROTLOC(1,1,INDEX)))THEN
          WRITE(6,2085)
          STOP 'MATRIX NOT ORTHOGONAL'
        ENDIF
  160 CONTINUE
!     << read in the evaluation grid >>
! -------------------------------------------------------------------------
! NPG        -- the total number of grid points of the evaluation grid
! RGRID(:,i) -- the i-th grid point in primitive fractional coordinates
! -------------------------------------------------------------------------
     
      CALL GRDGEN(MODE,NP,NPO)
      allocate (psi(npg))
      allocate (tot(npg))
      do INDEX=1,NPG
        write(*,*)"debugNGRID(:,1)",RGRID(:,INDEX)
       enddo
      stop
!     << find the surrounding primitve cell SPC of each atomic sphere >>
! ---------------------------------------------------------------
! SPC := Sum(i=1,3) [-s_i,+s_i] * a_i  with  s_i > 0
! and {a_1,a_2,a_3} being the primitive lattice vectors 
! ---------------------------------------------------------------
      CALL SPCGEN(NAT,RMT,ATMS)
      WRITE(6,2090)
      DO 170 JATOM=1,NAT
        WRITE(6,2100) JATOM,RMT(JATOM),(ATMS(I,JATOM),I=1,3)
  170 CONTINUE
!     << determine into which sphere each grid point r falls >>
! -------------------------------------------------------------------------
! if in interstitial:
! RGRID(1:3,i) -- the i-th grid point in (global) Cartesian coordinates
!
! if in muffin tin sphere around R(NX,NY,NZ) + R0(IAT)
! IREG (  i) -- the atom IAT for the i-th grid point
! ILAT (:,i) -- the lattice vector (NX,NY,NZ) for the i-th grid point
!               in primitive fractional coordinates 
! IRI  (  i) -- the radial interval the i-th grid point falls in
! RGRID(:,i) -- the value r - R - R0 for the i-th grid point 
!               in the local Cartesian coordinates of atom IAT
! -------------------------------------------------------------------------
      DO 175 INDEX=0,NDAT
  175 NREG(INDEX) = 0
      DO 180 IG=1,NPG
        CALL FINDMT(RGRID(1,IG),ATMS,nato,NDAT,INDEX,ILAT(1,IG),IRI(IG),R)
        IREG(IG) = INDEX
        NREG(INDEX)= NREG(INDEX) + 1
        IF(INDEX.GT.0)THEN
!         << in muffin tin sphere around R(NX,NY,NZ) + R0(IAT) >>
!         << transform r-R-R0 into local Cartesian coordinates >>
! -----------------------------------------------------------------------
! psi(r) = psi'(T^-1(r)) with psi' as the (LAPW1)-provided wave functions
! -----------------------------------------------------------------------
!         << r' := T^-1(r) >>
          DO 250 I=1,3
            RGRID(I,IG) = ROTLOC(I,1,INDEX)*R(1) &
                        + ROTLOC(I,2,INDEX)*R(2) &
                        + ROTLOC(I,3,INDEX)*R(3)
  250     CONTINUE
        ELSE
!         << in interstitial >>
          DO 260 I=1,3
            RGRID(I,IG) = R(I)
  260     CONTINUE
        ENDIF
  180 CONTINUE
      IF(NPG.GT.0)THEN
        WRITE(6,2110) 0,NREG(0),NREG(0)/DBLE(NPG)
        DO 275 INDEX=1,NDAT
          WRITE(6,2120) INDEX,IATNR(INDEX),NREG(INDEX), &
                        NREG(INDEX)/DBLE(NPG)
  275   CONTINUE
      ENDIF
!
!     << finally transform POS into global Cartesian coord. >>
      DO 280 INDEX=1,NDAT
        DO 290 J=1,3
          R(J) = POS(1,INDEX)*BR2(1,J) + POS(2,INDEX)*BR2(2,J) &
               + POS(3,INDEX)*BR2(3,J)
  290   CONTINUE
        DO 295 J=1,3
          POS(J,INDEX) = R(J)
  295   CONTINUE
  280 CONTINUE
!
! ######################################
! # PART II : wave function processing #
! ######################################
!
!     << read in wave function options >>
      READ (5,1080) SWITCH
      IF(SWITCH.NE.'DEP'.AND.SWITCH.NE.'NO ') &
         STOP 'ERROR: UNKNOWN POST-PROCESSING TOOL'
      DEPHAS = SWITCH.EQ.'DEP'
      READ (5,1090) SWITCH,IUNIT,WHPSI
      !write(*,*)"debug",switch,iunit,whpsi
      IF(SWITCH.NE.'RE '.AND.SWITCH.NE.'WAN'.AND.SWITCH.NE.'IM '.AND. &
         SWITCH.NE.'ABS'.AND.SWITCH.NE.'ARG'.AND.SWITCH.NE.'PSI') &
         STOP 'ERROR: UNKNOWN WAVE FUNCTION OPTION'
      ISPSI = SWITCH .EQ. 'PSI'
      WAN   = SWITCH .EQ. 'WAN'
      ISRE  = SWITCH .EQ. 'RE'
      ISIM  = SWITCH .EQ. 'IM'
      ISABS = SWITCH .EQ. 'ABS'
      ISARG = SWITCH .EQ. 'ARG'
      IF(IUNIT.EQ.'   '.OR.IUNIT.EQ.'ATU')IUNIT='AU '
      IF(IUNIT.NE.'ANG'.AND.IUNIT.NE.'AU ') &
         STOP 'ERROR: UNKNOWN UNITS OPTION'
      IF(WHPSI.EQ.'     ')WHPSI='LARGE'
      IF(WHPSI.NE.'SMALL'.AND.WHPSI.NE.'LARGE') &
         STOP 'ERROR: UNKNOWN REL. COMPONENT OPTION'
      LARGE = WHPSI .EQ. 'LARGE'
!     << writing to output is done later >>
!
!     << set up the augmentation functions  >>
!     << for each group of equivalent atoms >>
      CALL AUGGEN(REL,NAT,WHPSI)
!
!     << write wave function options to output >>
      WRITE(6,2130) WHPSI
      IF(DEPHAS)WRITE(6,2131)
      IF(ISPSI)THEN
        WRITE(6,2135) 'PSI',IUNIT
        WRITE(TITEL(1:67),3000) 'PSI',IUNIT,WHPSI
      ELSE
        WRITE(6,2135) SWITCH//'(PSI)',IUNIT
        WRITE(TITEL(1:67),3000) SWITCH//'(PSI)',IUNIT,WHPSI
      ENDIF
!
!     << read in wave function selection (and file handling) >>
      READ (5,*) ISKPT,ISEIG
      ALLKPT = ISKPT.LE.0
      ALLEIG = ISEIG.LE.0
      IF (WAN) THEN
       ALLKPT=.true.
       read(31,*)
       read(31,*)nemin,nemax
       nb=nemax-nemin+1
       allocate(uu(nb))
      ENDIF 
      READ(5,1100,IOSTAT=ierr)HANDLE
      IF(ierr.NE.0)HANDLE='    '
      GETABC = HANDLE.EQ.'READ' .OR. HANDLE.EQ.'REPL'
      PUTABC = HANDLE.EQ.'SAVE' .OR. HANDLE.EQ.'STOR'
      IF(.NOT.ALLKPT)WRITE(6,2140)'k-point',ISKPT
      IF(.NOT.ALLEIG)WRITE(6,2140)'band   ',ISEIG
      IF(GETABC)WRITE(6,2144)
      IF(PUTABC)WRITE(6,2145)
      IF((GETABC.OR.PUTABC).AND.(ALLKPT.OR.ALLEIG)) &
        STOP 'STORE/READ option only allowed for single state selection'
      IF(SHRMEM.AND.(ALLKPT.OR.ALLEIG)) &
        STOP 'Multiple states not allowed with EQUIVALENCE (PSI,RGRID)'
!
!     << set up constants and prefactors >>
! -----------------------------------------
!     prefactor = 1/sqrt( vol(UC) )
! -----------------------------------------
      PI     =  3.141592653589793238D0
      TWOPI  =  6.283185307179586477D0
      FOURPI = 12.566370614359172954D0
      PREFAC = 1.0D0 / SQRT(VUC)
      IF(IUNIT.EQ.'ANG') PREFAC = PREFAC / SQRT( 0.529177D0**3 )
!
!     << scale reciprocal basis vectors with 2pi >>
      DO 301 J=1,3
         DO 302 I=1,3
           BR3(I,J) = TWOPI * BR3(I,J) 
           BR4(I,J) = TWOPI * BR4(I,J) 
  302   CONTINUE
  301 CONTINUE
!
!     ---------
!     MAIN LOOP
!     ---------
      IF(.NOT.PUTABC)THEN
        IF(MODE.EQ.'ANY ')THEN
          WRITE(6,2150)'according to the grid point input file'
        ELSEIF(MODE(1:2).EQ.'2D')THEN
          WRITE(6,2150)'((psi(ix,iy),ix=1,nx),iy=1,ny)'
        ELSEIF(MODE(1:2).EQ.'3D')THEN
          WRITE(6,2150)'(((psi(ix,iy,iz),ix=1,nx),iy=1,ny),iz=1,nz)'
        ENDIF
        WRITE(2,2190)
      ENDIF
!     << read in k points >>
      KKK = 0
  300 READ(10,END=310,IOSTAT=IERR) (FK(I),I=1,3),BNAME,NK,NE, &
                                   WEIGHT,KKKABS
        KKK = KKK + 1
	IF(WAN) THEN
         do i=1,nb
	  read(32,*)uur,uui
          write(*,*)"debugu",uur,uui
	  uu(i)=uur+uui*cim
	 enddo
	ENDIF
        IF(IERR.LT.0) GOTO 310
        IF(IERR.GT.0) KKKABS = KKK
        NPW = NK - NLO
!        IF(NK.GT.NMAT) STOP 'NMAT too small'
        nmat=nk
        allocate (kx(nk),ky(nk),kz(nk))
        allocate ( FJ(0:LMAX7,NMAT,NRMT),DFJ(0:LMAX7,NMAT,NRMT))
        allocate ( BK(3,NMAT),COEF(NMAT),CF(NMAT))
!
!       << read in PW and local orbital wave vectors K >>
        READ(10) (KX(IK),KY(IK),KZ(IK),IK=1,NK)
!
        KFOUND = ALLKPT .OR. KKKABS.EQ.ISKPT 
        IF(.NOT.KFOUND) GOTO 340
        IF(.NOT.PUTABC)THEN
          WRITE(6,2160)KKKABS,BNAME,(FK(I),I=1,3)
          WRITE(2,2200)KKKABS,BNAME,(FK(I),I=1,3)
          IF(ALLEIG)THEN
            IF(ISPSI)THEN
              WRITE(2,2210)
            ELSE
              WRITE(2,2210)'min','max'
            ENDIF
            assign 2220 to IFORM
          ELSE
            assign 2230 to IFORM
          ENDIF
        ENDIF
!
!       << transform K+k into global Cartesian coordinates >>
        DO 320 IK=1,NK
          DO 330 J=1,3
            BK(J,IK) = BR3(1,J)*(KX(IK)+FK(1)) + BR3(2,J)*(KY(IK)+FK(2)) &
                     + BR3(3,J)*(KZ(IK)+FK(3))
  330     CONTINUE
  320   CONTINUE
!
!       << transform k into primitive fractional coordinates >>
        IF(.NOT.PRIM)THEN
          DO 325 J=1,3
            R(J) = BR3(1,J)*FK(1) + BR3(2,J)*FK(2) + BR3(3,J)*FK(3)
  325     CONTINUE
          DO 335 I=1,3
            FK(I) = BR2(I,1)*R(1) + BR2(I,2)*R(2) + BR2(I,3)*R(3)
  335     CONTINUE
        ELSE
          DO 337 I=1,3
            FK(I) = TWOPI * FK(I)
  337     CONTINUE
        ENDIF
!
!       << load spherical Bessel functions and their derivatives >>
! -----------------------------------------------------------------
! FJ (l,:,Rmt) :      j_l(|K+k|*r) at r = Rmt_a for all PW's K+k
! DFJ(l,:,Rmt) : d/dr j_l(|K+k|*r) at r = Rmt_a for all PW's K+k
! -----------------------------------------------------------------
        IF(.NOT.GETABC) CALL BESSEL(NPW,NMAT,BK,NMT,RAD,LMAX7,FJ,DFJ)
!
!       << read in individual eigen states >>
       
        COEF=0.d0
	DO I=1,NE
  340    READ(10,IOSTAT=IERR) IE,E,IEABS
         READ(10) (CF(IK),IK=1,NK)
	 IF (WAN.and.ie.ge.nemin.and.ie.le.nemax) THEN
           do ik=1,nk
            COEF(ik)=COEF(ik)+uu(ie-nemin+1)*cf(ik)
            write(*,*)"debug",ik,COEF(ik)
            write(*,*)"debug2",ik,uu(ie-nemin+1)
            write(*,*)"debug3",cf(ik)
           enddo
	  ENDIF
         ENDDO
!
!         << normalize the eigen functions properly >>
          DO 345 IK=1,NK
            COEF(IK) = PREFAC * COEF(IK)
  345     CONTINUE
!
!         << set up the eigen state's augmentation coefficients >>
!         << ALM, BLM, and CLM for each atom in the unit cell   >>
! ----------------------------------------------------------------------------
! in the muffin thin sphere around R + R_a one has:
!
! psi(r) = e^ikR Sum(lm) w_lm,a(|r-R-R_a|) Y*(*)_lm(T_a^-1(r-R-R_a))   with
!
! w_lm,a(r) = 4pi*i^l [ A_l,m,a *      u_l,a(r,E _l,a) +
!                       B_l,m,a * d/dE u_l,a(r,E _l,a) +
!                       C_l,m,a *      u_l,a(r,E'_l,a) ] * Rmt_a^2
!
! Here (*) stands for an optional additional complex conjugation on Y*_lm(...)
! WIEN95 : (*) =     and hence   *(*) = *
! WIEN97 : (*) = *   and hence   *(*) = 
! ----------------------------------------------------------------------------
          IL1 = NPW
          LATOM  = 0
          DO 350 JATOM=1,NAT
            IMAX = JRI(JATOM)
            DO 360 JNEQ=1,MULT(JATOM)
             LATOM = LATOM + 1
             CALL AUGPW(LATOM,NPW,ALM,ROTLOC,Y,bk,coef,nmat)
!            write(91,*)kkk,LATOM,ALM(1,1),ALM(2,1),ALM(5,2),ALM(5,3)
             IL=IL1
             CALL AUGLO(LATOM,IL,ALM,ROTLOC,Y,bk,coef,nmat)
	     IF (JNEQ.EQ.MULT(JATOM)) IL1=IL
!            write(91,*)kkk,LATOM,ALM(1,1),ALM(2,1),ALM(5,2),ALM(5,3)
!             << add 4pi*i^l Rmt^2 factor to ALM, BLM and CLM and >>
!             << set up the eigen state's augmentation functions  >>
! ----------------------------------------------------------------------------
! w_lm,a(r) = 4pi*i^l Rmt_a^2 * [ A_l,m,a *      u_l,a(r,E _l,a) + 
!                                 B_l,m,a * d/dE u_l,a(r,E _l,a) +
!                                 C_l,m,a *      u_l,a(r,E'_l,a) ]
! ----------------------------------------------------------------------------
              PHS = FOURPI * RMT(JATOM)*RMT(JATOM)
              LM = 0
              DO 460 L=0,LMAX7
               DO 470 M=-L,L
                LM=LM+1
                DO 480 I=1,IMAX
	         SUM=(0.d0,0.d0)
	         DO irf=1,nrf
	          SUM=SUM+ALM(LM,irf)*RRAD(I,L,irf,JATOM)
                 ENDDO
                 AUG(I,LM,LATOM)=SUM*PHS
  480           CONTINUE
  470          CONTINUE
               PHS = (0.0D0,1.0D0)*PHS
  460         CONTINUE
!	     write(91,*)kkk,LATOM,ALM(1,1),ALM(2,1),ALM(5,2),ALM(5,3)
  360       CONTINUE
  350     CONTINUE
          IF(PUTABC) GOTO 315
!	  write(91,*)kkk,AUG(34,5,1),AUG(34,1,2),AUG(34,2,5)
!
!         << now evaluate the wave function on the grid >>
          DO 500 IG=1,NPG
            IF(IREG(IG).EQ.0)THEN
!             << grid point in interstitial >>
              IF(LARGE)THEN
                CALL WAVINT(RGRID(1,IG),NPW,PSI(IG),bk,coef,nmat)
              ELSE
                PSI(IG)=(0.0D0,0.0D0)
              ENDIF
            ELSE
!             << grid point in atomic sphere at R(ILAT) + R_a(IREG) >>
!             << load calc. Bloch factor e^ikR >>
              ARG = FK(1)*ILAT(1,IG) + FK(2)*ILAT(2,IG)  &
                  + FK(3)*ILAT(3,IG)
              PHS = DCMPLX(COS(ARG),SIN(ARG))
              CALL WAVSPH(RGRID(1,IG),PHS,IREG(IG),IRI(IG),PSI(IG),Y)
            ENDIF
!	   write(93,*)IG,IREG(IG),PSI(IG)
  500     CONTINUE
        deallocate (kx,ky,kz)
        deallocate ( FJ,DFJ)
        deallocate ( BK,COEF,CF)
          IF (WAN) THEN
           write(*,*)"debug4",psi(1),tot(1)
           DO IG=1,NPG
	    tot(ig)=tot(ig)+psi(ig)
	    ENDDO
            GOTO 300
	   ENDIF
!
!         << correct for averaged phase factor >>
          IF(DEPHAS)THEN
            PHSAV = 0.0D0
            DO 501 IG=1,NPG
              IF(ABS(PSI(IG)).GT.1D-18) &
              PHSAV =  &
              PHSAV + DMOD(DATAN2(DIMAG(PSI(IG)),DBLE(PSI(IG)))+PI,PI)
  501       CONTINUE
            PHSAV = PHSAV/DBLE(NPG)
            PHS   = DCMPLX(COS(PHSAV),-SIN(PHSAV))
            DO 502 IG=1,NPG
               PSI(IG) = PSI(IG)*PHS
  502       CONTINUE
          ENDIF
!
          WRITE(TITEL(1:20),3010) KKKABS,IEABS
          WRITE(21,'(A)') TITEL(1:67)
          IF(ISPSI)THEN
            WRITE(21,3025) (PSI(IG),IG=1,NPG)
          ELSE
            IF(ISRE) then
              WRITE(21,3020) (dble(psi(IG)),IG=1,NPG)
            elseIF(ISC) then
              WRITE(21,3020) (dble(psi(IG)),IG=1,NPG)
	      WRITE(21,3020) (dimag(psi(IG)),IG=1,NPG)
            elseIF(ISim) then
              WRITE(21,3020) (dimag(psi(IG)),IG=1,NPG)
            elseIF(ISabs) then
              WRITE(21,3020) (abs(psi(IG)),IG=1,NPG)
            elseIF(ISarg) then
              WRITE(21,3020) (datan2(dimag(psi(IG)),dble(psi(ig))),IG=1,NPG)
            endif
          ENDIF
!
!         << find range of output data >>
          IF(ISPSI)THEN
            WRITE(2,IFORM)IEABS,E
          ELSE
            DATMIN = +1.0D+20
            DATMAX = -1.0D+20
            DO 530 IG=1,NPG
            IF(ISRE) then
              DATMIN = MIN(DATMIN,dble(psi(IG)))
              DATMAX = MAX(DATMAX,dble(psi(IG)))
            elseIF(ISim) then
              DATMIN = MIN(DATMIN,dimag(psi(IG)))
              DATMAX = MAX(DATMAX,dimag(psi(IG)))
            elseIF(ISabs) then
              DATMIN = MIN(DATMIN,abs(psi(IG)))
              DATMAX = MAX(DATMAX,abs(psi(IG)))
            elseIF(ISarg) then
              DATMIN = MIN(DATMIN,datan2(dimag(psi(IG)),dble(psi(ig))))
              DATMAX = MAX(DATMAX,datan2(dimag(psi(IG)),dble(psi(ig))))
            endif                                                                         
  530       CONTINUE
            WRITE(2,IFORM)IEABS,E,DATMIN,DATMAX
          ENDIF
!
!         << echo wave functions to the output >>
          WRITE(6,2170)IEABS,E,KKKABS
          IF(MODE.EQ.'ANY ')THEN
            IF(ISPSI)THEN
              WRITE(6,2185)' ',(PSI(IG),IG=1,NPG,NPO(0))
            ELSE
            IF(ISRE) then
              WRITE(6,2180)' ',(dble(psi(IG)),IG=1,NPG,NPO(0))
            elseIF(ISim) then
              WRITE(6,2180)' ',(dimag(psi(IG)),IG=1,NPG,NPO(0))
            elseIF(ISabs) then
              WRITE(6,2180)' ',(abs(psi(IG)),IG=1,NPG,NPO(0))
            elseIF(ISarg) then
              WRITE(6,2180)' ',(datan2(dimag(psi(IG)),dble(psi(ig))),IG=1,NPG,NPO(0))
            endif
            ENDIF
            WRITE(6,'()')
          ELSE
!           << data stored in gnuplot order                 >>
!           << POS = IZ + (IY-1)*NP(3) + (IX-1)*NP(3)*NP(2) >>
            NPY = NP(3)
            NPX = NP(3)*NP(2)
            DO 550 IZ=0,NP(3)-1,NPO(3)
              DO 560 IY=0,NP(2)-1,NPO(2)
                IG = 1 + IZ + IY*NPY
                IF(ISPSI)THEN
                  WRITE(6,2185)'o',(PSI(IG+IX*NPX),IX=0,NP(1)-1,NPO(1))
                ELSE
            IF(ISRE) then
              WRITE(6,2180)'o',(dble(psi(IG+IX*NPX)),IX=0,NP(1)-1,NPO(1))
            elseIF(ISim) then
              WRITE(6,2180)'o',(dimag(psi(IG+IX*NPX)),IX=0,NP(1)-1,NPO(1))
            elseIF(ISabs) then
              WRITE(6,2180)'o',(abs(psi(IG+IX*NPX)),IX=0,NP(1)-1,NPO(1))
            elseIF(ISarg) then
              WRITE(6,2180)'o',(datan2(dimag(psi(IG+IX*NPX)),dble(psi(ig+IX*NPX))),IX=0,NP(1)-1,NPO(1))
            endif
                ENDIF
  560         CONTINUE
              WRITE(6,'()')
  550       CONTINUE
          ENDIF

  315   IF(IE.LT.NE)GOTO 340
        IF(KFOUND.AND..NOT.PUTABC)WRITE(2,'()')
!        deallocate (kx,ky,kz)
!        deallocate ( FJ,DFJ)
!        deallocate ( BK,COEF,CF)                                                 
      GOTO 300 
  310 CONTINUE
      IF (WAN) THEN
       write(21,3020)(cdabs(tot(IG))/kkk,IG=1,NPG)
       open(unit=22,file='SrVO3.psiarg',status='unknown')
       write(22,3020)(datan2(dimag(tot(IG)),dble(tot(IG))),IG=1,NPG)
       close(22)
!       write(21,*)
!       write(21,3020)(dimag(tot(IG))/kkk,IG=1,NPG)
      ENDIF
!
      REWIND(2)
  570 READ(2,'(A)',END=580)TITEL(1:64)
        DO 590 I=64,1,-1
          IF(TITEL(I:I).NE.' ')THEN
            WRITE(6,'(A)')TITEL(1:I)
            GOTO 570
          ENDIF
  590   CONTINUE
        WRITE(6,'()')
      GOTO 570
  580 CLOSE(2,STATUS='DELETE')
      IF(PUTABC)THEN
        REWIND 21
        ENDFILE 21
      ENDIF
      RETURN
!
 1000 FORMAT(A80)
 1010 FORMAT(A4,23X,I3/13X,A4)
 1020 FORMAT(6F10.5)
 1030 FORMAT(4X,I4,1X,3(3X,F10.7):/15X,I2)
 1040 FORMAT(A10,5X,I5,2(5X,F10.5),5X,F5.2)
 1050 FORMAT(20X,3F10.8)
 1060 FORMAT(I4)
 1070 FORMAT(3(3I2,F10.5/))
 1080 FORMAT(A3)
 1090 FORMAT(A3,1X,A3,1X,A5)
 1100 FORMAT(A4)
!
 2000 FORMAT(/A/)
 2010 FORMAT(1X,A4,' LATTIC WITH ',I5,' INEQUIV. ATOMS/UC USING ', &
             A4,'. AUGMENTATION')
 2020 FORMAT(/' LATTIC CONSTANTS:',3F12.7,' (in bohr)' &
             /' UNIT CELL ANGLES:',3F12.7,' (in degree)')
 2030 FORMAT(/' SYMMETRY OPERATIONS' &
             /' -------------------' &
             /' y = {Q|t}(x) : y_i = Sum(j) Q_ij x_j + t_i', &
             /' with y_i and x_j in conventional fractional coordinates' &
            //' symm    Q(:,1)  Q(:,2)  Q(:,3)    t(:)')
 2040 FORMAT(I5,3I8,F13.5/2(5X,3I8,F13.5/))
 2050 FORMAT( ' POSITIONS OF THE BASIS ATOMS' &
             /' ----------------------------' &
             /' x = Sum(j=1,3) f_i a_i  with  f_i in [0,1[', &
              '  (in the conventional unit cell)' &
            //' atom    f_1      f_2      f_3   ', &
              '        x [bohr]     y [bohr]     z [bohr]')
 2060 FORMAT(I5,1X,3F9.5,3X,3F13.7)
 2070 FORMAT(/' SYMMETRY ADAPTED LOCAL ROTATION MATRICES' &
             /' ----------------------------------------' &
             /' x'' = T^-1(x) : x''_i = Sum(j) x_j T_ji' &
             ,'  with x_j and x''_i in Cartesian coord.' &
            //' atom  symm.      T(:,1)      T(:,2)      T(:,3)')
 2080 FORMAT(2(I5,1X),3F12.6,2(/12X,3F12.6)/)
 2085 FORMAT(/'CURRENT ROTATION MATRIX IS NOT ORTHOGONAL')
 2090 FORMAT(/' PRIMITIVE CELLS SURROUNDING THE MUFFIN TIN SPHERES' &
             /' --------------------------------------------------' &
             /' cell = Sum(i=1,3) [-s_i,+s_i] a_i', &
              '  with  a_i = primitive lattice vector' &
            //' atom     RMT         s_1      s_2      s_3')
 2100 FORMAT(I5,F10.5,3X,3F9.5)
 2110 FORMAT(/' GRID POINT DISTRIBUTION' &
             /' -----------------------' &
             /' region  atom  grid points  percentage' &
             /I7,3X,'int',I10,2P,F11.1,' %')
 2120 FORMAT(I7,I5,I11,2P,F11.1,' %')
 2130 FORMAT(/' WAVE FUNCTION OPTIONS' &
             /' ---------------------' &
             /' evaluation of the ',A5,' relativistic component', &
              ' of the wave functions')
 2131 FORMAT( ' after dephasing of the wave function')
 2135 FORMAT( ' data provided    :  ',A,'  [in ',A3,' units]')
 2140 FORMAT( ' selected ',A7,' :',I5)
 2144 FORMAT(/' evaluation based on previously stored', &
              ' augmentation coefficients')
 2145 FORMAT(/' augmentation coefficients stored for later re-use'/ &
             /' >>> no wave function data produced! <<<')
 2150 FORMAT(/' ==================' &
             /' WAVE FUNCTION DATA' &
             /' ==================' &
             /' order: ',A/)
 2160 FORMAT( ' k-point',I4,' : ',A10,' = (',F8.4,',',F8.4,',',F8.4,')' &
             /' ',55('-'))
 2170 FORMAT( ' band',I4,' : E = ',F12.6,'  (k-point:',I4,')')
 2180 FORMAT(1P,A1,6E13.5:/(1X,6E13.5))
 2185 FORMAT(1P,A1,2(' (',E13.5,',',E13.5,')':):/ &
            (   1X,2(' (',E13.5,',',E13.5,')':)))
!
 2190 FORMAT( ' WAVE FUNCTION INFO' &
             /' ------------------')
 2200 FORMAT( ' k-point',I4,' : ',A10,' = (',F8.4,',',F8.4,',',F8.4,')')
 2210 FORMAT( ' band        energy':'     ',A3,'(data)   ',A3,'(data)')
 2220 FORMAT(I5,F14.6,2X,1P,2E12.3)
 2230 FORMAT( ' band',I7,' :',F14.6:1P,SP,' , min/max =',E11.3, &
              ' /',E11.3)
!
 3020 FORMAT(1P,10E16.8)
 3025 FORMAT(1P,2E16.8,3X,2E16.8)
 3000 FORMAT('k =..... , n =...... : ',A8,' [',A3,' units] ', &
             '-- ',A5,' rel. component')
 3010 FORMAT('k =',I5,' , n =',I6)
      END
