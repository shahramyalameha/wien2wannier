!!! wien2wannier/SRC_wplot/ylm.f

SUBROUTINE YLM(V,LMAX,Y)
! -----------------------------------------------------------------
! This subroutine is taken from SRC_LAPW2 and subsitutes the old
! version of ylm.f which was found to be numerically unstable for
! arguments close to but not on the z-axis (P. Balah, priv. comm.)
! -----------------------------------------------------------------
  use const, only: DPk, TAU

  implicit none

  integer,      intent(in)  :: LMAX
  real(DPk),    intent(in)  :: V(3)
  complex(DPk), intent(out) :: Y(*)
!
!     ..................................................................
! 1.     PROGRAM UNIT 'YLM'
!           Calculates spherical harmonics
!           FORTRAN 77 SUBROUTINE
!
! 2.     PURPOSE
!           The spherical harmonics (Condon and Shortley convention)
!             Y(0,0),Y(1,-1),Y(1,0),Y(1,1),Y(2,-2) ... Y(LMAX,LMAX)
!           for vector V (given in Cartesian coordinates)
!           are calculated. In the Condon Shortley convention the
!           spherical harmonics are defined as
!                             +------+
!                        m    |   1     m              im(Phi)
!           Y(l,m) = (-1)  -+ | -----  P (cos(Theta)) e
!                            \| 2(Pi)   l
!                  m
!           where P (cos(Theta)) is the normalized Associated Legendre
!                  l
!           function. Thus,
!                                          m      *
!                            Y(l,-m) = (-1) Y(l,m)
!
!
! 3.     USAGE
!           DOUBLE PRECISION V(3), Y(5*5)
!           V(1) = ...
!           V(2) = ...
!           V(3) = ...
!           CALL YLM(V,4,Y)
!
!        ARGUMENT-DESCRIPTION
!           V      - DOUBLE PRECISION vector, dimension 3        (input)
!                    Must be given in Cartesian coordinates.
!                    Conversion of V to polar coordinates gives the
!                    angles Theta and Phi necessary for the calculation
!                    of the spherical harmonics.
!           LMAX   - INTEGER value                               (input)
!                    upper bound of L for which spherical harmonics
!                    will be calculated
!                    constraint:
!                       LMAX .GE. 0 (not checked)
!           Y      - COMPLEX*16 array, dimension (LMAX+1)**2    (output)
!                    contains the calculated spherical harmonics
!                    Y(1)                   for L .EQ. 0 (M = 0)
!                    Y(2), ..., Y(4)        for L .EQ. 1 (M = -1, 0, 1)
!                    ...
!                    Y(LMAX*LMAX+1), ..., Y((LMAX+1)*(LMAX+1))
!                                           for L .EQ. LMAX
!                                              (M = -L,...,L)
!                    constraint:
!                       Dimension of Y .GE. (LMAX+1)**2 (not checked)
!
!        USED SUBROUTINES (DIRECTLY CALLED)
!           none
!
!        INDIRECTLY CALLED SUBROUTINES
!           none
!
!        UTILITY-SUBROUTINES (USE BEFOREHAND OR AFTERWARDS)
!           none
!
!        INPUT/OUTPUT (READ/WRITE)
!           none
!
! 4.     REMARKS
!           none
!
! 5.     METHOD
!           The basic algorithm used to calculate the spherical
!           harmonics for vector V is as follows:
!
!           Y(0,0)
!           Y(1,0)
!           Y(1,1)
!           Y(1,-1) = -Y(1,1)
!           DO L = 2, LMAX
!              Y(L,L)   = f(Y(L-1,L-1)) ... Formula 1
!              Y(L,L-1) = f(Y(L-1,L-1)) ... Formula 2
!              DO M = L-2, 0, -1
!                 Y(L,M) = f(Y(L-1,M),Y(L-2,M)) ... Formula 2
!                 Y(L,-M)= (-1)**M*Y(L,M)
!              ENDDO
!           ENDDO
!
!           In the following the necessary recursion formulas and
!           starting values are given:
!
!        Start:
!                        +------+
!                        |   1
!           Y(0,0) =  -+ | -----
!                       \| 4(Pi)
!
!                                   +------+
!                                   |   3
!           Y(1,0) =  cos(Theta) -+ | -----
!                                  \| 4(Pi)
!
!                                     +------+
!                                     |   3    i(Phi)
!           Y(1,1) =  - sin(Theta) -+ | ----- e
!                                    \| 8(Pi)
!
!        Formula 1:
!
!           Y(l,l) =
!                           +--------+
!                           | (2l+1)   i(Phi)
!            -sin(Theta) -+ | ------  e       Y(l-1,l-1)
!                          \|   2l
!
!        Formula 2:
!                                  +---------------+
!                                  |  (2l-1)(2l+1)
!           Y(l,m) = cos(Theta) -+ | -------------- Y(l-1,m)  -
!                                 \|   (l-m)(l+m)
!
!                                    +--------------------+
!                                    |(l-1+m)(l-1-m)(2l+1)
!                              -  -+ |-------------------- Y(l-2,m)
!                                   \|  (2l-3)(l-m)(l+m)
!
!        Formula 3: (not used in the algorithm because of the division
!                    by sin(Theta) which may be zero)
!
!                                    +--------------+
!                      cos(Theta)    |  4(m+1)(m+1)   -i(Phi)
!           Y(l,m) = - ---------- -+ | ------------  e       Y(l,m+1) -
!                      sin(Theta)   \| (l+m+1)(l-m)
!
!                                    +--------------+
!                                    |(l-m-1)(l+m+2)  -2i(Phi)
!                              -  -+ |-------------- e        Y(l,m+2)
!                                   \| (l-m)(l+m+1)
!
! 6.     DATE
!           26. April 1994                                   Version 1.2
!
!        INSTITUT FUER TECHNISCHE ELEKTROCHEMIE            --  TU VIENNA
!     ..................................................................

  integer   :: I2L, I4L2, INDEX, INDEX2, L, M, MSIGN
  real(DPk) :: A, B, C, AB, ABC, ABMAX, ABCMAX
  real(DPk) :: D4LL1C, D2L13
  real(DPk) :: COSTH, SINTH, COSPH, SINPH
  real(DPk) :: TEMP1, TEMP2, TEMP3
  real(DPk) :: YLLR, YLL1R, YL1L1R, YLMR
  real(DPk) :: YLLI, YLL1I, YL1L1I, YLMI

!        Y(0,0)
!
  YLLR = 1/SQRT(2*TAU)
  YLLI = 0
  Y(1) = cmplx(YLLR, YLLI, DPk)

!        continue only if spherical harmonics for (L .GT. 0) are desired
!
  IF (LMAX .LE. 0) RETURN

!        calculate sin(Phi), cos(Phi), sin(Theta), cos(Theta)
!        Theta, Phi ... polar angles of vector V
!
  ABMAX  = MAX(ABS(V(1)),ABS(V(2)))
  IF (ABMAX .GT. 0.0D+0) THEN
     A = V(1)/ABMAX
     B = V(2)/ABMAX
     AB = SQRT(A*A+B*B)
     COSPH = A/AB
     SINPH = B/AB
  ELSE
     COSPH = 1.0D+0
     SINPH = 0.0D+0
  ENDIF
  ABCMAX = MAX(ABMAX,ABS(V(3)))
  IF (ABCMAX .GT. 0.0D+0) THEN
     A = V(1)/ABCMAX
     B = V(2)/ABCMAX
     C = V(3)/ABCMAX
     AB = A*A + B*B
     ABC = SQRT(AB + C*C)
     COSTH = C/ABC
     SINTH = SQRT(AB)/ABC
  ELSE
     COSTH = 1.0D+0
     SINTH = 0.0D+0
  ENDIF

!        Y(1,0)
!
  Y(3) = cmplx(sqrt(3.0_DPk)*YLLR*COSTH, 0, DPk)

!        Y(1,1) ( = -DCONJG(Y(1,-1)))
!
  TEMP1 = -SQRT(1.5D+0)*YLLR*SINTH
  Y(4) = cmplx(temp1*cosph, temp1*sinph, DPk)
  Y(2) = -conjg(Y(4))

  DO L = 2, LMAX
     INDEX  = L*L+1
     INDEX2 = INDEX + 2*L
     MSIGN  = 1 - 2*MOD(L,2)

!        YLL = Y(L,L) = f(Y(L-1,L-1)) ... Formula 1
!
     YL1L1R = real(Y(INDEX-1))
     YL1L1I = aimag(Y(INDEX-1))
     TEMP1 = -sqrt(real(2*L+1, DPk)/2/L) * SINTH
     YLLR = TEMP1*(COSPH*YL1L1R - SINPH*YL1L1I)
     YLLI = TEMP1*(COSPH*YL1L1I + SINPH*YL1L1R)
     Y(INDEX2) = cmplx(YLLR, YLLI, DPk)
     Y(INDEX)  = MSIGN * conjg(Y(index2))
     INDEX2 = INDEX2 - 1
     INDEX  = INDEX  + 1

!        YLL1 = Y(L,L-1) = f(Y(L-1,L-1)) ... Formula 2
!               (the coefficient for Y(L-2,L-1) in Formula 2 is zero)
!
     TEMP2 = sqrt(real(2*L+1, DPk))*COSTH
     YLL1R = TEMP2*YL1L1R
     YLL1I = TEMP2*YL1L1I
     Y(INDEX2) = cmplx(YLL1R, YLL1I, DPk)
     Y(INDEX)  = -MSIGN * conjg(Y(INDEX2))
     INDEX2 = INDEX2 - 1
     INDEX  = INDEX  + 1

     I4L2 = INDEX2 - 4*L + 2
     I2L  = INDEX2 - 2*L
     D4LL1C = COSTH*sqrt(real(4*L*L-1, DPk))
     D2L13  = -sqrt(real(2*L+1, DPk)/(2*L-3))

     DO M = L - 2, 0, -1
!        YLM = Y(L,M) = f(Y(L-2,M),Y(L-1,M)) ... Formula 2
!
        TEMP1 = 1.0D+0/sqrt(real((L+M)*(L-M), DPk))
        TEMP2 = D4LL1C*TEMP1
        TEMP3 = D2L13*sqrt(real((L+M-1)*(L-M-1), DPk))*TEMP1
        YLMR = TEMP2*real(Y(I2L))  + TEMP3*real(Y(I4L2))
        YLMI = TEMP2*aimag(Y(I2L)) + TEMP3*aimag(Y(I4L2))
        Y(INDEX2) = cmplx(YLMR, YLMI, DPk)
        Y(INDEX)  = MSIGN*conjg(Y(INDEX2))

        MSIGN  = -MSIGN
        INDEX2 = INDEX2 - 1
        INDEX  = INDEX  + 1
        I4L2   = I4L2   - 1
        I2L    = I2L    - 1
     END DO
  END DO

!
!        End of 'YLM'
!
END SUBROUTINE YLM


!!/---
!! Local Variables:
!! mode: f90
!! End:
!!\---
!!
!! Time-stamp: <2016-07-15 11:45:50 assman@faepop71.tu-graz.ac.at>
