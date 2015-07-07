int_addr equ $8F8F                   ; Start of interrupt code


;===============================

; Install IM 2 Grayscale Routine

;===============================


OpenGray:

 ld hl,$CE00                         ; Save six bytes after 
_plotScreen

 ld de, SixBytes                     ;  since our int routine 
overwrites it
 ld bc, 6

 ldir


 ld hl,$8E00                         ; Source = $8E00 (Start of 
vector table)
 ld de,$8E01                         ; Destination = $8E01

 ld (hl),$8F                         ; Set first byte so it is copied 
to all of them ($8F8F)

 ld bc,256                           ; 256 bytes (size of vector 
table)
 ldir                                ; (DE) <- (HL), BC=BC-1, Loop 
till B=0

 

 ld hl,int_copy                      ; Source = grayscale interrupt 
routine)
 ld de,int_addr                      ; Destination = $8F8F (as 
specified in vector table)
 ld bc,int_end-int_start  
           ; Length of custom interrupt routine
 ldir                                ; (DE) <- 
(HL), BC=BC-1, Loop till B=0



 call _runindicoff                   ; Run indicator.. I hate the run indicator (don't you?)



;=====================================================================
==========
; Set up parameters to pass the interrupt handler via the alternate 
register set
;=====================================================================
==========
 di


 exx                                ; Exchange regular registers with alternate registers


 ld b,$3c                           ; $3C used in int routine for Port 0 ($FC00)

 ld c,0                             ; Used because variables get 
cleared often in the int routine
 ld d,5                             ; 5 is the user counter

 ld e,%110110                       ; This is used to XOR $3C to get 
$0A and vise versa
 ld hl,UserCounter                  ; HL points to the counter, 
needed in the int routine
 exx                                ; Normal registers restored; 
alternate registers contain parameters


 xor a                        

 ld (UserCounter),a                  ; Clear user counter variable




 ld a,$8E                            ; Set up address of vector table
 ld i,a                              ;  MSB = $8E


                                     ;  LSB = (byte supplied by data bus - random)




 im 2                                ; Interrupt Mode 2
 ei                                  ; Enable Interrupt
s
 ret                                 ; Return to calling program




;=============================================================
; Close Grayscale Handler

;=============================================================



CloseGray:

 im 1                                 ; Back to Interrupt Mode 1

 ld a,$3C

 out (0),a                            ; Display Back to $FC00



 call _clrLCD                         ; Clear Screen



 ld hl,_plotSScreen                   ; Clear Plotscreen

 ld hl,_plotSScreen+1

 ld (hl), 0

 ld bc,1024

 ldir




 ld hl, SixBytes                      ; Restore the six bytes after _plotScreen

 ld de, $CE00                         ;  since our int routine 
overwrites it
 ld bc, 6

 ldir




 ret


int_copy:

;.org $8f8f     nope, not in TASM       Interrupt routine starts here



int_start:

 ex af,af'                             ; Exchange registers. 

 exx                                   ; Parameters were passed via 
alternate register set


 in a,(3)                              ; Is the LCD in the middle of 
refreshing?
 bit 1,a

 jr z,leave_int                        ; If so, immediately exit 
interrupt routine


 inc (hl)                              ; UserCounter = UserCounter + 1

 out (c),b                             ; Output $3C or $0A (see 
change_pages) to Port $0 
                                       ;  This forms the addresses 
$FC00 or $CA00
 dec d                                 ; Subtract from grayscale 
counter
 call z,reset_int_counter              ; If the grayscale falls to 0, 
then reset the counter
 ld a,d


 cp 2                                  ; User Counter equal 2?

 call z,change_pages                   ; If so, change the page



leave_int:

 in a,(3)                              ; Get byte from Port 3

 rra                                   ; Check bit 0 (ON interrupt 
status)
 ld a,c                                ; A = 0 

 adc a,9                               ; A = 9 + Carry Flag (either 
$09 or $0A)
 out (3),a                             ; Send $09 if ON not pressed, 
$0A otherwise
 ld a,$0B

 out (3),a                             ; Send $0B to Port 3



 ex af,af'                             ; Exchange registers..

 exx

 ei                                    ; Enable Interrupts

 reti                                  ; Go home



reset_int_counter = $-int_copy+$8f8f

 ld d,5                                ; Reset grayscale counter to 5

change_pages = $-int-copy+$8f8f

 ld a,e                                ; E = %110110 

 xor b                                 ; XOR $3C with E to get $0A, 
and XOR $0A with E to get $3C
                                       ; Thus the B register 
alternates between $FC and $CA


 ld b,a                                ; B register saved for later 
use
 ret                                   ; Return


int_end:

UserCounter: .db 5

SixBytes: .db 0,0,0,0,0,0



.end



