C     RECONSTRUCTION
C     0!
C     Lluís Torres 
C     TFM
C     FORTRAN 95

      PROGRAM RECONSTRUCTION

      USE MODEL

C-----(SYSTEM)------------------------------------------------
C     NODES, EDGES, CONNECTIVITY
      INTEGER N, M, z
C     +1 -1 EDGES RATIO (1 => ALL +1), (0 => ALL -1)
      REAL*8 p
C     TEMPERATURE (TEMP := k_B·T)
      REAL*8 TEMP
C     p-LIST, TEMP-LIST
      INTEGER p_SIZE, TEMP_SIZE
      REAL*8,ALLOCATABLE:: p_LIST(:), TEMP_LIST(:)
C     ORIGINAL SYSTEM ARRAYS
      TYPE(MULTI_ARRAY),ALLOCATABLE:: NBR_0(:)
      TYPE(MULTI_ARRAY),ALLOCATABLE:: INBR_0(:)
      TYPE(MULTI_ARRAY),ALLOCATABLE:: JJ_0(:)
C-----(SIMULATION)---------------------------------------------
C     SAMPLE SIZE (# OF SPIN CONFIGURATIONS)
      INTEGER C
C     TOTAL MONTE-CARLO STEPS (MCS) FOR RECONSTRUCTION
      INTEGER TAU
C     FICTICIOUS TEMPERATURE
      REAL*8 TEMP_F
C     FICTICIOUS TEMPERATURE STEP
      REAL*8 TF_STEP
C     NUMBER OF GRAPHS TO SIMULATE FOR EVERY P VALUE
      INTEGER NSEEDS
C     SEED NUMBER, INITIAL SEED NUMBER
      INTEGER SEED, SEEDini
      PARAMETER(SEEDini = 100)
C     ESTIMATE TIME VARIABLES
      REAL*4 TIME1, TIME2, time
C     SIMULATION VARIABLES
      INTEGER, ALLOCATABLE:: D(:,:)
      TYPE(MULTI_ARRAY),ALLOCATABLE:: NBR(:)
      TYPE(MULTI_ARRAY),ALLOCATABLE:: INBR(:)
      TYPE(MULTI_ARRAY),ALLOCATABLE:: JJ(:)
      LOGICAL valid
      REAL*8 DPL
      REAL*8 PL
C-----(SPIN CONFIGURATION SAVING VARIABLES)-------------------
C     STORE SPIN CONFIGURATION AS N/zip_size INTEGERS
      INTEGER zip_size
      INTEGER, ALLOCATABLE:: bin(:)
      INTEGER, ALLOCATABLE:: decimal(:)
      INTEGER, ALLOCATABLE:: array(:)
C-----(DUMMY)-------------------------------------------------
      INTEGER ITEMP, Ip, IC
      INTEGER IMC, IPAS, i
      CHARACTER(4) str
      CHARACTER(3) str1, str2, str3, str4
      INTEGER, ALLOCATABLE:: LAMBDA(:,:)
      REAL*8, ALLOCATABLE:: funct(:,:)
      INTEGER zmax
      REAL*8 H !TRANSVERSE FIELD (EQUAL TO 0 IN CLASSIC MODEL)
      INTEGER NP, NM !NUMBER OF POSITIVE AND NEGATIVE EDGES
C~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
      INTEGER SC !NOT USED IN THIS PROGRAM
      INTEGER H_SIZE !NOT USED IN THIS PROGRAM
      REAL*8,ALLOCATABLE:: H_LIST(:) !NOT USED IN THIS PROGRAM
      INTEGER R !NOT USED IN THIS PROGRAM
      INTEGER MCINI !NOT USED IN THIS PROGRAM

C-----------------------------------------------------------------------
C     START
C-----------------------------------------------------------------------

      PRINT*, 'SYSTEM RECONSTRUCTION'

C***********************************************************************
C     READ SIMULATION VARIABLES FROM INPUT FILE
      CALL READ_INPUT(N,z,R,TEMP_SIZE,TEMP_LIST,H_SIZE,H_LIST,
     . p_SIZE,p_LIST,C,MCINI,NSEEDS,SC,zip_size,TAU)
      zmax = N-1
C     ALLOCATION
      ALLOCATE(decimal(1:N/zip_size))
      ALLOCATE(array(1:N))
      ALLOCATE(bin(1:N))
      ALLOCATE(D(1:C,1:N))
      ALLOCATE(LAMBDA(1:C,1:N))
      ALLOCATE(funct(-1:1,-zmax:zmax))
C***********************************************************************
      CALL CPU_TIME(TIME1)
C***********************************************************************
C     THERE IS NO TRANSVERSE FIELD
      H = 0.00
      WRITE(str,'(f4.2)') H
      str2 = str(1:1)//str(3:4)
C***********************************************************************

C     FOR ALL TEMP VALUES
      DO ITEMP = 1,TEMP_SIZE
      TEMP = TEMP_LIST(ITEMP)
      WRITE(str,'(f4.2)') TEMP
      str1 = str(1:1)//str(3:4)

C     FOR ALL p VALUES
      DO Ip = 1,p_SIZE
      p = p_LIST(IP)
      WRITE(str,'(f4.2)') p
      str3 = str(1:1)//str(3:4)

C     CREATE DIRECTORY TO SAVE THE GRAPHS AND COUPLINGS FOUND WITH THE ALGORITHM
      CALL SYSTEM('mkdir -p results/graphs/pl/p_'//str3)

C***********************************************************************
      CALL SYSTEM('mkdir -p results/accuracy/T'//str1//'_Γ'//str2)
      OPEN(UNIT=10,FILE='results/accuracy/T'//str1//'_Γ'//str2//
     .'/g_'//str3//'.dat')
C***********************************************************************

C     FOR ALL SEEDS
      DO SEED = SEEDini,SEEDini+NSEEDS-1
      WRITE(str4,'(i3)') SEED

C***********************************************************************
C     INITIAL RANODM GRAPH (THE SAME AS THE ORIGINAL ONE)
      CALL setr1279(SEED)
      CALL IRG(N,z,NBR_0,INBR_0,JJ_0,M)
C     INITIAL RANDOM COUPLINGS
      CALL setr1279(SEED)
      CALL RCA(N,p,NBR_0,INBR_0,JJ_0)
C***********************************************************************
C     READ THE SAMPLE
      OPEN(UNIT=3,FILE='results/sample/T'//str1//'_Γ'//str2//
     .'/S_'//str3//'_'//str4//'.bin',FORM='UNFORMATTED')
      DO IC = 1,C
            READ(3) decimal
            CALL DEC2BIN(N,zip_size,bin,decimal)
            CALL BIN2ARRAY(N,bin,array)
            D(IC,:) = array
      END DO
      CLOSE(3)
C***********************************************************************
C     INITIAL FICTICIOUS TEMPERATURE
      TEMP_F = -LOG(0.5d0*(1+TANH(1.D0/TEMP)))/z
      TF_STEP = TEMP_F/TAU
C***********************************************************************
C     GET THE NUMBER OF POSITIVE AND NEGATIVE EDGES
      CALL GETCOUPLINGS(N,NBR_0,JJ_0,NP,NM)

C     UNKNOWN GRAPH
      CALL setr1279(555)
      CALL IRS(N,NP,NM,NBR,INBR,JJ)

C     KNOWN GRAPH
      ! CALL setr1279(SEED)
      ! CALL IRG(N,z,NBR,INBR,JJ,M)
      ! CALL RCS(N,NP,NBR,INBR,JJ)
C***********************************************************************
      CALL CLASS_LAMBDA(N,C,D,NBR,JJ,LAMBDA)
      CALL CLASS_FUNCTION(zmax,TEMP,funct)
C***********************************************************************
C     INITIAL PSEUDOLIKELIHOOD
      PL = PSEUDO(N,C,D,TEMP,NBR,JJ)
C***********************************************************************
C     MONTE-CARLO SIMULATION
      DO IMC = 1,TAU
            DO IPAS = 1,M
            CALL PSEUDOLIKELIHOOD(N,C,D,valid,TEMP_F,
     .                        DPL,NBR,INBR,JJ,zmax,funct,LAMBDA)
            IF (valid) THEN
                  PL = PL + DPL
            END IF
            END DO
            TEMP_F = TEMP_F - TF_STEP
      ENDDO
C***********************************************************************
      WRITE(10,*) SEED, GAMMAA(N,M,NBR,JJ,NBR_0,JJ_0)

C     SAVE GRAPH AND COUPLINGS
      IF (ITEMP==1) THEN
      OPEN(UNIT=55,FILE='results/graphs/pl/p_'//str3
     . //'/'//str4//'.dat')
      WRITE(55,'(A,X,A,2X,A)') "#","N","z"
      WRITE(55,'(I3,2X,I1)') N, z
      WRITE(55,'(A)') "# NBR"
      DO i = 1, N
            DO j = 1, SIZE(NBR(i)%v)
                  WRITE(55, '(I3,2X)', advance='no') NBR(i)%v(j)
            END DO
            WRITE(55, *)
      END DO
      WRITE(55,'(A)') "# JJ"
      DO i = 1, N
            DO j = 1, SIZE(JJ(i)%v)
                  WRITE(55, '(I3,2X)', advance='no') JJ(i)%v(j)
            END DO
            WRITE(55, *)
      END DO
      CLOSE(55)
      END IF
C***********************************************************************
      DO i = 1,N
            DEALLOCATE(NBR(i)%v)
            DEALLOCATE(INBR(i)%v)
            DEALLOCATE(JJ(i)%v)
      END DO
      DEALLOCATE(NBR)
      DEALLOCATE(INBR)
      DEALLOCATE(JJ)

      DO i = 1,N
            DEALLOCATE(NBR_0(i)%v)
            DEALLOCATE(INBR_0(i)%v)
            DEALLOCATE(JJ_0(i)%v)
      END DO
      DEALLOCATE(NBR_0)
      DEALLOCATE(INBR_0)
      DEALLOCATE(JJ_0)
C***********************************************************************
C     ESTIMATE EXECUTION TIME
200   FORMAT (A,I4,A,I3,A,I3,A,I3,A,I3,A,I3)
      IF ((SEED.EQ.SEEDini).AND.(p.EQ.p_LIST(1)).AND. 
     .(TEMP.EQ.TEMP_LIST(1))) THEN
      CALL CPU_TIME(TIME2)
      time = (TIME2-TIME1)*NSEEDS*p_SIZE*TEMP_SIZE
      WRITE(*,200) "ESTIMATED TIME: ", INT(time/3600), ' h',
     . INT((time/3600-INT(time/3600))*60), ' min', 
     . INT((time/60-INT(time/60))*60), ' s'
      END IF
C***********************************************************************
      
      END DO !SEED

C***********************************************************************
      CLOSE(10)
C***********************************************************************

      END DO !Ip
      END DO !ITEMP

C***********************************************************************
      CALL CPU_TIME(TIME2)
      time = (TIME2-TIME1)
      WRITE(*,200) "CPU TIME: ", INT(time/3600), ' h',
     . INT((time/3600-INT(time/3600))*60), ' min', 
     . INT((time/60-INT(time/60))*60), ' s'
C***********************************************************************

      END PROGRAM RECONSTRUCTION