;jamesrubingh980501   
;      лллл   ллл     л    лл
;       л    л   л   лл   л  л
;       л    л        л  л    л
;       л     ллл     л  л    л   JSnake v1.0
;    л  л        л    л  л    л       By James Rubingh
;    л  л    л   л    л   л  л
;     лл      ллл  л ллл   лл
;  Source code, to a cheap rip off of Nibbles!  
;  Please Email any Questions or comments < jaymzroo@juno.com > 
;   also, if you take out the title picture the program is smaller 
;   by about 330 bytes! delete all lines with a *, and the pic data.


   .include asm86.h
   .include ti86asm.inc
   .org _asm_exec_ram

delat = _textShadow             ;1 length of delay
score = _textShadow+1           ;2 score
x = _textShadow+3               ;1 x value of head
y = _textShadow+4               ;1 y value of head
length = _textShadow+5          ;1 length of snake
lastd = _textShadow+6           ;1 value of last key last cycle
rndmx = _textShadow+7           ;1 Apple's X coordinate
rndmy = _textShadow+8           ;1 Apple's Y coordinate
array = GRAPH_MEM               ;>10 array containing snakes path

   nop                          ;tell shell there is a title
   jp start                     ;skip the next part when running prog
   .dw 0                        ;table type 
   .dw msgTitle                 ;location of the title string (end of src)
start:
   
  call _runindicoff             ;turn off the running thing in corner
  call _clrLCD                  ;clear the screen

  ld de,$fca3                   ;*  load de w/ where to show picture
  call showjs10                 ;*  call the picture drawing routine

  call pause                    ;*  pause for the title screen
  
  call _clrLCD                  ;clear the screen, ask for speed
  ld bc,$0401
  ld (_curRow),bc
  ld hl,msgGame
  call _puts
  call showmail
  
  ld hl,$ff80
  ld b,4
mail2:
  call invert2
  djnz mail2                    ;invert the bottom 8 lines of video mem

checkbegin:
  halt
  call GET_KEY                  ;what speed, jump to there
  cp K_EXIT
  jp z,doneGame
  cp K_F1
  jr z,f1
  cp K_F2
  jr z,f2
  cp K_F3
  jr z,f3
  cp K_F4
  jr z,f4
  cp K_F5
  jr z,f5
  jr checkbegin                 ;no keypress, try again
f1:
 ld a,$1a 
 jr donespeed
f2:
 ld a,$28 
 jr donespeed
f3:
 ld a,$40 
 jr donespeed
f4:
 ld a,$55 
 jr donespeed
f5:
 ld a,$6a
donespeed: 
  ld (delat),a         ;store that value for later
  call _clrLCD
startgame:
  call initialize
  call Drawfield
  call newapple

MAIN:           ;mainloop
  call GET_KEY
  cp K_EXIT
  jp z,doneGame
  cp K_MORE
  call z,pause

nokeypress:  
  cp K_UP
  jr z,mu
  cp K_DOWN
  jr z,md
  cp K_LEFT
  jr z,ml
  cp K_RIGHT
  jr z,mr
  
  ld a,(lastd)
  jr nokeypress

backdekeys:
 call deadyet
 or a
 jp nz,Died
 call shiftdata                         ;must keep track of everywhere the
 call showhead                          ;that the snake has been
 call take
 call delay
 jr MAIN                                ;pause for a moment, Z80 is too fast!!
                                                                  ;-)
mu:
 ld (lastd),a
 ld hl,y
 dec (hl)
 jr backdekeys
ml:
 ld (lastd),a
 ld hl,x
 dec (hl)
 jr backdekeys
mr:
 ld (lastd),a
 ld hl,x
 inc (hl)
 jr backdekeys
md:
 ld (lastd),a
 ld hl,y
 inc (hl)
 jr backdekeys

showhead:
 call getxy               ;calculate (b,c) and then draw 4 pixel block
 call do4
 ret

take:
 ld a,(length)                  ;find the length of snake, then double it 
 add a,a                        ;(b/c of (X,Y) for each 1 part of snake)
 ld c,a
 ld b,0
 ld hl,array                    ;go that far into the array of data
 add hl,bc
 ld a,(hl)                      ;load it into a, see if it is not part  
 cp 100                         ;of the snake, in case the snake was just
 ret z                          ;extended. Length would equal longer than
 add a,a                        ;the snake actually is
 ld b,a
 inc hl                         ;double that number, to find the pixel
 ld a,(hl)
 add a,a
 ld c,a                         ;double the y value too
take4:                          ;delete 4 pixels at (b,c)
 call DelPixel
 inc b
 call DelPixel
 inc c
 call DelPixel
 dec b
 call DelPixel
 ret

do4:                            ;draw 4 pixels
 call PutPixel
 inc b
 call PutPixel
 inc c                          
 call PutPixel
 dec b
 call PutPixel
 ret

getxy:
 ld a,(x)
 add a,a
 ld b,a
 ld a,(y)
 add a,a
 ld c,a
 ret


deadyet:
 call getxy             ;load into bc the x,y coordinates of snake
 call GetPixel
 or a
 ret z
 
 ld a,(rndmx)
 cp b
 jr nz,died
 ld a,(rndmy)
 cp c
 jr z,HITAPPLE
died:
 ld hl,msgOuch
 ld bc,$0703
 ld (_curRow),bc        ;where to show string
 call _puts             ;display 'CRASH'

 call pause
 ld a,1                 ;tell main loop to exit
 ret

HITAPPLE:
 ld a,(length)
 add a,5
 ld (length),a          ;Add five to the length
 cp 80 
 jp z,beatlevel         ;beat this level

 ld a,(rndmx)
 add a,a
 ld b,a
 ld a,(rndmy)
 add a,a
 ld c,a                 ;delete the old apple
 call take4

newapple:
 ld a,r                 ;basically a random register
 and 30
 ld c,a
 ld (rndmy),a
 ld a,r
 and %00111110
 ld b,a
 ld (rndmx),a
 call GetPixel
 jr nz,newapple
 
 call do4
 xor a                  ;if A is anything else, the main loop exit
 ret

initialize:
 ld hl,GRAPH_MEM
 ld (hl),100
 ld de,GRAPH_MEM+1
 ld bc,240
 ldir
 ld hl,0
 ld (score),hl
 ld a,K_RIGHT
 ld (lastd),a
 ld a,15
 ld (x),a
 ld (y),a
 ld a,10
 ld (length),a
 ret

Drawfield:
 ld hl,$Fc00            ;Horizontal border
 call invert2           ;all off, so turn them on
 ld hl,$ffe0            ;all bytes at hl
 call invert2

 ld hl,$fc00            ;draw the outside borders
 ld de,15
 ld b,64
df2:
 ld a,(hl)
 or %11000000 
 ld (hl),a
 add hl,de
 ld a,(hl)
 or 3
 ld (hl),a
 inc hl
 djnz df2
 ret

invert2:                        ;invert 16 bytes of video memory at HL
 push bc                        ;2, 1 pixel tall horizontal lines=16 bytes
 ld b,32
invertloop:
 ld a,(hl)
 xor 255
 ld (hl),a
 inc hl
 djnz invertloop                ;dec b / cp 0 /jr nz,invertloop
 pop bc
 ret

shiftdata:
 ld b,2
shift: 
 push bc
 ld a,(length)
 add a,a
 ld c,a
 ld b,0
 ld hl,array
 add hl,bc
 ld e,l
 ld d,h
 inc de
 inc bc
 lddr                           
 pop bc
 djnz shift
 
 ld hl,array
 ld a,(x)
 ld (hl),a
 inc hl
 ld a,(y)
 ld (hl),a
 ret

delay:
 ld a,(delat)
 ld e,a
dela:
 dec e
 jr nz,dela
 dec a
 jr nz,dela
 ret

pause:
 push af
ploop: 
 halt
 call GET_KEY
 cp K_ENTER
 jr nz,ploop
 pop af
 ret

PutPixel:
 call FIND_PIXEL        ;0,0 at top left like on an 85
 ld de,$fc00
 add hl,de
 or (hl)
 ld (hl),a
 ret

GetPixel:               ;if A equals 0, then pixel is off
 push bc
 call FIND_PIXEL
 ld de,$fc00
 add hl,de
 and (hl)
 pop bc
 ret

DelPixel:
 call FIND_PIXEL
 ld de,$fc00
 add hl,de
 cpl
 and (hl)
 ld (hl),a
 ret


showmail:
  ld bc,$381c
  ld (_penCol),bc
  ld hl,msgEmail
  call _vputs
 ret

showjs10:
 ld hl,js10pic
 ld a,31
show1:
 push de
 ld bc,10
 ldir
 pop de
 ex de,hl
 ld bc,16
 add hl,bc
 ex de,hl
 dec a
 jr nz,show1
 ret

Died:

doneGame:
  call _clrLCD
  ret
beatlevel:
 ld bc,$0603
 ld (_curRow),bc
 ld hl,msgBeat
 call _puts
 call pause
 ld a,1
 ret


FIND_PIXEL:   ;by jimmy mardell -only borrowed part of this souce-
 push bc
 push de
 ld hl,ExpTable
 ld d,0
 ld a,b
 and $07
 ld e,a
 add hl,de
 ld e,(hl)
 ld h,d
 srl b
 srl b
 srl b
 ld a,c
 add a,a
 add a,a
 ld l,a
 add hl,hl
 add hl,hl
 ld a,e
 ld e,b
 add hl,de
 pop de
 pop bc
 ret

ExpTable:
 .db $80,$40,$20,$10,$08,$04,$02,$01

js10pic:  
  .db %00000000,%01111111,%00000000,%00011111,%11000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00000000,%01110001,%11100000,%11110001,%11100000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00000000,%01100001,%11100001,%10000000,%11100000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000001,%11000011,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000011,%11000111,%00000000,%00000000,%00000000,%01100000,%00000000,%00111110,%00000000
  .db %00000000,%00000011,%11001110,%00000000,%00000000,%00000001,%11000000,%00000011,%11101111,%10000000
  .db %00000000,%00000011,%10001110,%00000000,%00000000,%00011111,%11000000,%00000111,%10000111,%10000000
  .db %00000000,%00000011,%10011110,%00000000,%00000000,%00111011,%11000000,%00011111,%00000111,%11000000
  .db %00000000,%00000111,%10011110,%00000000,%00000000,%00000111,%10000000,%00110011,%00000011,%11000000
  .db %00000000,%00000111,%00011111,%00000000,%00000000,%00000111,%10000000,%01110000,%00000011,%11000000
  .db %00000000,%00000111,%00011111,%11100000,%00000000,%00000111,%10000000,%11100000,%00000011,%11000000
  .db %00000000,%00001111,%00001111,%11111110,%00000000,%00000111,%00000000,%11000000,%00000011,%11000000
  .db %00000000,%00001110,%00001111,%11111111,%10000000,%00000111,%00000001,%11000000,%00000011,%10000000
  .db %00000000,%00001110,%00000001,%11111111,%11000000,%00001111,%00000001,%11000000,%00000011,%10000000
  .db %00000000,%00001110,%00000000,%00011111,%11000000,%00001110,%00000011,%10000000,%00000111,%10000000
  .db %00000000,%00011100,%00000000,%00000111,%11000000,%00001110,%00000011,%10000000,%00000111,%00000000
  .db %00000000,%00011100,%00000000,%00000111,%11000000,%00001110,%00000111,%10000000,%00000111,%00000000
  .db %00000000,%00111100,%00000000,%00000011,%11000000,%00011100,%00001111,%00000000,%00001100,%00000000
  .db %00000000,%00111000,%00000000,%00000011,%10000000,%00011100,%00001111,%00000000,%00011100,%00000000
  .db %00000000,%00111000,%01100000,%00000011,%10000000,%00111100,%00001111,%00000000,%00111000,%00000000
  .db %00000000,%01111000,%01100000,%00000111,%00000000,%00111100,%00001111,%00000000,%00110000,%00000000
  .db %00000000,%01111000,%11100000,%00000111,%00000000,%00111000,%00001111,%00000000,%01100000,%00000000
  .db %00000000,%01110000,%11100000,%00001110,%00000000,%00111000,%00001111,%10000000,%11000000,%00000000
  .db %00000000,%11110000,%11110000,%00011100,%00000000,%01111000,%00001111,%10000001,%10000000,%00000000
  .db %00000000,%11110000,%01111100,%00111000,%00000000,%01111111,%10000111,%11000111,%00000000,%00000000
  .db %00000000,%11110000,%00011111,%11100000,%00000011,%11100000,%00000001,%11111100,%00000000,%00000000
  .db %00110001,%11100000,%00000000,%00000000,%00000110,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00111001,%11000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00111111,%10000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00111110,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000
  .db %00111100,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000,%00000000


msgTitle: .db "By James Rubingh",0   
msgEmail: .db "Jaymzroo@juno.com",0
              ;012345678901234567890
msgGame:  .db      "JSnake v1.0     "
          .db "    Speed F1-F5",0
msgOuch:  .db "CRASH!",0
msgBeat:  .db "You Won!",0
.end           
