### FILE="Main.annotation"
## Copyright:   Public domain.
## Filename:    LEM_GEOMETRY.agc
## Purpose:     A section of Luminary revision 116.
##              It is part of the source code for the Lunar Module's (LM) 
##              Apollo Guidance Computer (AGC) for Apollo 12.
##              This file is intended to be a faithful transcription, except
##              that the code format has been changed to conform to the
##              requirements of the yaYUL assembler rather than the
##              original YUL assembler.
## Reference:   pp. 321-326
## Assembler:   yaYUL
## Contact:     Ron Burkey <info@sandroid.org>.
## Website:     www.ibiblio.org/apollo/index.html
## Mod history: 2017-01-22 MAS  Created from Luminary 99.
##		2017-03-07 RSB	Transcribed, and then proofed comment-text using
##				3-way diff vs Luminary 99 and Luminary 131.
##				(Admittedly, the former is more for detecting errors
##				in Luminary 99 than the other way around.)

## Page 321
                BANK            23                              
                SETLOC          LEMGEOM                         
                BANK                                            

                SBANK=          LOWSUPER                        
                EBANK=          XSM                             

# THESE TWO ROUTINES COMPUTE THE ACTUAL STATE VECTOR FOR LM,CSM BY ADDING
# THE CONIC R,V AND THE DEVIATIONSR,V. THE STATE VECTORS ARE CONVERTED TO
# METERS B-29 AND METERS/CSEC B-7 AND STORED APPROPRIATELY IN RN,VN OR
# R-OTHER,V-OTHER FOR DOWNLINK.  THE ROUTINES NAMES ARE SWITCHED IN THE
# OTHER VEHICLES COMPUTER.

# INPUT
#   STATE VECTOR IN TEMPORARY STORAGE AREA
#   IF STATE VECTOR IS SCALED POS B27 AND VEL B5
#      SET X2 TO +2
#   IF STATE VECTOR IS SCALED POS B29 AND VEL B7
#      SET X2 TO 0

# OUTPUT
#   R(T) IN RN, V(T) IN VN, T IN PIPTIME
# OR
#   R(T) IN R-OTHER, V(T) IN V-OTHER   (T IS DEFINED BY T-OTHER)

                COUNT*          $$/GEOM                         
SVDWN2          BOF             RVQ                             # SW=1=AVETOMID DOING W-MATRIX INTEG.
                                AVEMIDSW                        
                                +1                              
                VLOAD           VSL*                            
                                TDELTAV                         
                                0               -7,2            
                VAD             VSL*                            
                                RCV                             
                                0,2                             
                STOVL           RN                              
                                TNUV                            
                VSL*            VAD                             
                                0               -4,2            
                                VCV                             
                VSL*                                            
                                0,2                             
                STODL           VN                              
                                TET                             
                STORE           PIPTIME                         
                RVQ                                             
## Page 322
SVDWN1          VLOAD           VSL*                            
                                TDELTAV                         
                                0               -7,2            
                VAD             VSL*                            
                                RCV                             
                                0,2                             
                STOVL           R-OTHER                         
                                TNUV                            
                VSL*            VAD                             
                                0               -4,2            
                                VCV                             
                VSL*                                            
                                0,2                             
                STORE           V-OTHER                         
                RVQ                                             

## Page 323
#          THE FOLLOWING ROUTINE TAKES A HALF UNIT TARGET VECTOR REFERRED TO NAV BASE COORDINATES AND FINDS BOTH
# GIMBAL ORIENTATIONS AT WHICH THE RR MIGHT SIGHT THE TARGET. THE GIMBAL ANGLES CORRESPONDING TO THE PRESENT MODE
# ARE LEFT IN MODEA AND THOSE WHICH WOULD BE USED AFTER A REMODE IN MODEB. THIS ROUTINE ASSUMES MODE 1 IS TRUNNION
# ANGLE LESS THAN 90 DEGS IN ABS VALUE WITH ARBITRARY SHAFT, WITH A CORRESPONDING DEFINITION FOR MODE 2. MODE
# SELECTION AND LIMIT CHECKING ARE DONE ELSEWHERE.

#          THE MODE 1 CONFIGURATION IS CALCULATED FROM THE VECTOR AND THEN MODE 2 IS FOUND USING THE RELATIONS

#          S(2) = 180 + S(1)
#          T(2) = 180 - T(1)

#     THE VECTOR ARRIVES IN MPAC WHERE TRG*SMNG OR *SMNB* WILL HAVE LEFT IT.

RRANGLES        STORE           32D                             
                DLOAD           DCOMP                           # SINCE WE WILL FIND THE MODE 1 SHAFT
                                34D                             # ANGLE LATER, WE CAN FIND THE MODE 1
                SETPD           ASIN                            # TRUNNION BY SIMPLY TAKING THE ARCSIN OF
                                0                               # THE Y COMPONENT, THE ASIN GIVING AN
                PUSH            BDSU                            # ANSWER WHOSE ABS VAL IS LESS THAN 90 DEG
                                LODPHALF                        
                STODL           4                               # MODE 2 TRUNNION TO 4.

                                LO6ZEROS                        
                STOVL           34D                             # UNIT THE PROJECTION OF THE VECTOR
                                32D                             #   IN THE X-Z PLANE
                UNIT            BOVB                            # IF OVERFLOW,TARGET VECTOR IS ALONG Y
                                LUNDESCH                        # CALL FOR MANEUVER UNLESS ON LUNAR SURF
                STODL           32D                             # PROJECTION VECTOR.
                                32D                             
                SR1             STQ                             
                                S2                              
                STODL           SINTH                           # USE ARCTRIG SINCE SHAFT COULD BE ARB.
                                36D                             
                SR1                                             
                STCALL          COSTH                           
                                ARCTRIG                         
## Page 324
                PUSH            DAD                             # MODE 1 SHAFT TO 2.
                                LODPHALF                        
                STOVL           6                               
                                4                               
                RTB                                             # FIND MODE 2 CDU ANGLES.
                                2V1STO2S                        
                STOVL           MODEB                           
                                0                               
                RTB                                             # MODE 1 ANGLES TO MODE A.
                                2V1STO2S                        
                STORE           MODEA                           
                EXIT                                            

                CS              RADMODES                        # SWAP MODEA AND MODEB IF RR IN MODE 2.
                MASK            ANTENBIT                        
                CCS             A                               
                TCF             +4                              

                DXCH            MODEA                           
                DXCH            MODEB                           
                DXCH            MODEA                           

                TC              INTPRET                         
                GOTO                                            
                                S2                              
## Page 325
# GIVEN RR TRUNNION AND SHAFT (T,S) IN TANGNB,+1,FIND THE ASSOCIATED
# LINE OF SIGHT IN NAV BASE AXES.  THE HALF UNIT VECTOR, .5(SIN(S)COS(T),
# -SIN(T),COS(S)COS(T)) IS LEFT IN MPAC AND 32D.

                SETLOC          INFLIGHT                        
                BANK                                            

                COUNT*          $$/GEOM                         

RRNB            SLOAD           RTB                             
                                TANGNB                          
                                CDULOGIC                        
                SETPD           PUSH                            # TRUNNION ANGLE TO 0
                                0                               
                SIN             DCOMP                           
                STODL           34D                             # Y COMPONENT

                COS             PUSH                            # .5 COS(T) TO 0
                SLOAD           RTB                             
                                TANGNB          +1              
                                CDULOGIC                        
RRNB1           PUSH            COS                             # SHAFT ANGLE TO 2
                DMP             SL1                             
                                0                               
                STODL           36D                             # Z COMPONENT

                SIN             DMP                             
                SL1                                             
                STOVL           32D                             
                                32D                             
                RVQ                                             

# THIS ENTRY TO RRNB REQUIRES THE TRUNNION AND SHAFT ANGLES IN MPAC AND MPAC +1 RESPECTIVELY

RRNBMPAC        STODL           20D                             # SAVE SHAFT CDU IN 21.
                                MPAC                            # SET MODE TO DP.  (THE PRECEEDING STORE
                                                                # MAY BE DP, TP OR VECTOR.)
                RTB             SETPD                           
                                CDULOGIC                        
                                0                               
                PUSH            SIN                             # TRUNNION ANGLE TO 0
                DCOMP                                           
                STODL           34D                             # Y COMPONENT
                COS             PUSH                            # .5COS(T) TO 0
                SLOAD           RTB                             # PICK UP CDU'S.
                                21D                             
                                CDULOGIC                        
                GOTO                                            
                                RRNB1                           
## Page 326
## <br>This page has nothing on it.


