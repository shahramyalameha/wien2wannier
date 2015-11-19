  PROGRAM join_vectorfilesc
  !joins multiple WIEN2K vector files to one for further processing
  !for complex vector files
  !P. Wissgott
   use util
  
   implicit none

 character*50 seedname
 integer nkpoints,nfiles
 integer iarg,argcount !command line input argument counter
 integer jatom,natom,i,j,k,jl,jj,jk
 integer lmax,lomax,nloat
 integer nlines   !# lines in a file
 integer nemin,nemax,tmpint !read in dummys
 integer counter
 integer unitkgen,unitstruct,unitvector, unitenergy, unittargetvector,unittargetenergy
 integer kcounter
 real*8, allocatable :: kpoints(:,:) !k-mesh points 
 character*70 argdummy,startmessage
 real*8,allocatable    :: XK(:),YK(:),ZK(:)
 INTEGER            NE, NV
 DOUBLE PRECISION   SX, SY, SZ, WEIGHT
 CHARACTER*3        IPGR,filenr
 CHARACTER*10       KNAME
DOUBLE PRECISION, allocatable ::  EIGVAL(:)
 DOUBLE PRECISION, allocatable ::   E(:,:),ELO(:,:,:)
INTEGER, pointer :: KZZ(:,:)
!_REAL      DOUBLE PRECISION, allocatable ::  Z(:,:)
!_COMPLEX
      DOUBLE COMPLEX, allocatable :: Z(:, :)
 type(structure) lattice
 character*15 vectorfileend, energyfileend
 DOUBLE PRECISION   eorb_ind


  !default fileending: non spin-polarized
  vectorfileend = ".vector"
  energyfileend = ".energy"
  startmessage = "++ join vector files of standard input ++"
  unitkgen = 1
  unitvector = 2
  unitenergy = 3
  unittargetvector = 4
  unittargetenergy = 5

  LMAX = 13
  LOMAX = 3
  nloat = 3
  !command line argument read-in
  iarg=iargc()
  argcount = 1
write(*,*)iarg
  if ((iarg.ge.2).and.(iarg.le.3)) then
    do j=1,iarg
        call getarg(j,argdummy)
        if (argdummy(1:1).eq.'-') then
            if ((argdummy(2:3).eq.'up').or.(argdummy(2:3).eq.'dn')) then     
               !for spin-polarized calc. the fileendings have additional up/dn
              vectorfileend = ".vector"//argdummy(2:3)
              energyfileend = ".energy"//argdummy(2:3)
              startmessage = "++ join vector files of spin-polarized input files:"//argdummy(2:3)//" ++"
            elseif ((argdummy(2:5).eq.'soup').or.(argdummy(2:5).eq.'sodn')) then  
               vectorfileend = ".vectorso"//argdummy(4:5)
               energyfileend = ".energyso"//argdummy(4:5)
               startmessage = "++ join vector files of spin-polarized spin-orbit input files:"//argdummy(4:5)//" ++"
            endif
         else
            if (argcount.eq.1) then
               read(argdummy,*)seedname
               argcount = argcount + 1
            else
               read(argdummy,*)nfiles
            endif
        endif
     enddo
 else
   write(*,*) "Usage: join_vectorfilesc [-up/-dn] <case> <numberofparallelfiles>"
   stop
 endif

 open(unit=unitkgen,file=clearspace(seedname)//'.outputkgen',status='old')
 open(unit=unitstruct,file=clearspace(seedname)//'.struct',status='old')
 call countatoms(unitstruct,lattice)
 call readin_lattice(unitstruct,unitkgen,lattice)
 natom = size(lattice%elements)
 call count_kpoints(unitkgen,clearspace(seedname)//'.outputkgen',nkpoints)
 close(unitkgen)
 close(unitstruct)


 allocate(XK(nkpoints),YK(nkpoints),ZK(nkpoints))
 allocate( E(LMAX,natom) )
 allocate( ELO(0:LOMAX,nloat,natom) )
 

 open(unit=unittargetvector,file=clearspace(seedname)//clearspace(vectorfileend),status='unknown',form='unformatted')
 open(unit=unittargetenergy,file=clearspace(seedname)//clearspace(energyfileend),status='unknown',form='formatted')    
 
 
 do j=1,nfiles
    write(filenr,"(I3)")j
    open(unit=unitvector,file=clearspace(seedname)// &
               & clearspace(vectorfileend)//"_"//clearspace(filenr),status='old',form='unformatted')
    open(unit=unitenergy,file=clearspace(seedname)//  &
               & clearspace(energyfileend)//"_"//clearspace(filenr),status='old',form='formatted')
    do jatom= 1,natom
       read(unitvector) (E(jl,jatom),jl=1,LMAX)
       read(unitvector) ((ELO(jl,k,jatom),jl=0,LOMAX),k=1,nloat)
       read(unitenergy,'(100(f9.5))') (E(jl,jatom),jl=1,LMAX),eorb_ind
       read(unitenergy,'(100(f9.5))') ((ELO(jl,k,jatom),jl=0,LOMAX),k=1,nloat)
       if (j.eq.1) then
          write(unittargetvector) (E(jl,jatom),jl=1,LMAX)
          write(unittargetvector) ((ELO(jl,k,jatom),jl=0,LOMAX),k=1,nloat)
          write(unittargetenergy,'(100(f9.5))') (E(jl,jatom),jl=1,LMAX),eorb_ind
          write(unittargetenergy,'(100(f9.5))') ((ELO(jl,k,jatom),jl=0,LOMAX),k=1,nloat)
       endif
    enddo
    do jk=1,nkpoints/nfiles
       read(unitvector) SX, SY, SZ, KNAME, NV, NE, WEIGHT, IPGR
       allocate( KZZ(3,NV) )
       read(unitenergy,'(3e19.12,a10,2i6,f5.1,a3)') SX, SY, SZ, KNAME, NV, NE, WEIGHT, IPGR 
       read(unitvector) (KZZ(1,I),KZZ(2,I),KZZ(3,I),I=1,NV)
       write(unittargetvector)SX, SY, SZ, KNAME, NV, NE, WEIGHT, IPGR
       write(unittargetenergy,'(3e19.12,a10,2i6,f5.1,a3)') SX, SY, SZ, KNAME, NV, NE, WEIGHT, IPGR 
       write(unittargetvector) (KZZ(1,I),KZZ(2,I),KZZ(3,I),I=1,NV)
       allocate(Z(NV,NE))
       allocate(EIGVAL(NE))
       do jj = 1, NE
         read(unitvector) I, EIGVAL(I)
         write(unittargetvector)I,EIGVAL(I)
         read(unitenergy,*) I, EIGVAL(I)
         write(unittargetenergy,*)I,EIGVAL(I)
         !_REAL     read(unitvector) (Z(jl,I),jl=1,NV)
         !_REAL     write(unittargetvector) (Z(jl,I),jl=1,NV)
         !_COMPLEX
        read(unitvector) (Z(jl,I),jl=1,NV)
         !_COMPLEX      
        write(unittargetvector) (Z(jl,I),jl=1,NV)
      enddo
      deallocate(Z,EIGVAL,KZZ)
    enddo
    close(unitvector)
    close(unitenergy)
 enddo
 close(unittargetvector)
 close(unittargetenergy)
 
    

END PROGRAM

