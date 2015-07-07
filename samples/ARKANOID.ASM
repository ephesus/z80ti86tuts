; Game:      Arkanoid v1.0
; Author:    James Rubingh
; Email:     James@acz.org (2015 ephesus@gmail.com)
; WebPage:   http://members.tripod.com/~jaymzroo (2015 http://wrive.com)
; Alliance:  www.acz.org
; Date:      December 1998

; Just a quick note. Since i was using the Graph_mem for grayscale I 
; didnt use a video buffer to stop flickering, so any flickering 
; was avoided but its still there with sprites and the ball.

; I use SDR16. Thanks to JL for that routine. 

 .include ti86asm.inc   ;ACZ include files ROM86.h RAM86.h ASM86.h 
 .org _asm_exec_ram


data = $9000            ;level data 128 bytes, last data byte $9000+127
balla = $9000+128       ;ball data 1.0=up 1=down 2.scale 34.xy 5.Dead
score = _textShadow
lives = _textShadow+2
level = _textShadow+3
x = _textShadow+23
p = _textShadow+4               ;0 = normal nz=big ass paddle
PS_addy = _textShadow+5 ;used to indicate which RAM addy to draw to
ballz = _textShadow+7
temp = _textShadow+8
tempy = _textShadow+9
blocks = _textShadow+11         ;how many blocks are on the screen
b = _textShadow+18      
much = _textShadow+19   ;how many hits since the ball last hit the paddle
dead = _textShadow+20
switch = _textShadow+22
FP_RLD = _textShadow+24
bonusHL = _textShadow+26        ;bonus pointer to video memory
bonusSP = _textShadow+28        ;bonus Sprite pointer
bonusTY = _textShadow+30        ;bonus Type 0-3
bonusTIME = _textShadow+31      ;The bonus counter
bonusW = _textShadow+32
flag = _textShadow+25
delayt = _textShadow+33
;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

 .db 0
 jp start
 .dw 0
 .dw Title
  
;----- estoy iniciando -----
  
start:
  call _runindicoff
  call _clrLCD
  call cbuffer
  ld hl,arktitle-1      ;check if the title screen data is there
  rst 20h
  rst 10h
  jr c,start_wo_title
start_with_title:
  ld a,b
  ex de,hl
  call $4633            ;trans AHL -> ASIC
  set 6,a
  out (5),a
  inc a
  out (6),a
  ld de,-($4000-2)      ;You have to move the pointer back one 16k section
  add hl,de             ;because the ROM thinks I am in the third 16k
  ld de,$fc00           ;section, but its really been moved to the 2nd
  ld bc,$400-64         ;with the out (5),a command. then also skip one
  ldir                  ;word of the data, hence -($4000-2)
  ld de,$ca00
  ld bc,$400-64
  ldir
  ld a,$0d
  out (5),a
  ld a,65
  out (6),a
  call OpenGray
graytitlewait:
 ld a,%00111111         ;exact subroutine as e_p except without
 out (1),A              ;the halt command.
 in a,(1)
 bit 5,a
 jr nz,graytitlewait

start_wo_title:  
  call CloseGray        ;turn off grayscale so that you can use _getkey
  call cbuffer          
  call _clrLCD          
  ld hl,$0402
  ld (_curRow),hl
  ld hl,TITLE
  call _puts
  ld hl,$0204
  ld (_curRow),hl
  ld hl,Author
  call _puts            ;display Big sized string


OficialBegin:           ;done with title screen. Begin  
  
  ld hl,$3023
  ld (_penCol),hl
  ld hl,hightext
  call _vputs
  ld hl,$3034
  ld (_penCol),hl
  ld hl,(highscore)
  call d_zm_deci
  ld hl,$3720
  ld (_penCol),hl
  ld hl,choosespeed
  call _vputs
  
initialkeycheck:
  call _GetKy

  cp K_EXIT
  ret z
  cp K_F1
  jr nz,checkF2
  ld a,$FF
  ld (delayt),a
  jr BeyondDelaySetup
checkF2:
  cp K_F2
  jr nz,checkF3
  ld a,$f0
  ld (delayt),a
  jr BeyondDelaySetup
checkF3:
  cp K_F3
  jr nz,checkF4
  ld a,$d0
       ld (delayt),a
  jr BeyondDelaySetup
checkF4:
  cp K_F4
  jr nz,checkF5
  ld a,$90
  ld (delayt),a
  jr BeyondDelaySetup
checkF5:
  cp K_F5
  jr nz,initialkeycheck
  
  ld hl,skipdelay
  ld de,selfmodify
  ld bc,3
  ldir
  jr BeyondDelaySetup2
BeyondDelaySetup:
  call fixself          ;fix selfmodification
BeyondDelaySetup2:
  call OpenGray
  ld a,($C008)          ;if its not all the way up, increase the 
  cp 31                 ;contrast by 1
  jr z,nochange
  inc a
  out (2),a
nochange:
  
  ld hl,_textShadow
  xor a
  ld de,_textShadow+1
  ld bc,168
  ld (hl),a
  ldir
  ld de,$9001
  ld hl,$9000
  ld bc,$500
  ld (hl),a
  ldir                  ;clear the array table data 

 call _clrLCD
 call cbuffer           ;clears the second buffer for grayscale shit
                        ;which starts 6 bytes after the Graph Memory did
  
  res 1,(iy+$0d)        ; shit, i need a beer
  ld a,1
  ld (level),a
  add a,3
  ld (lives),a


  call unpacklevel      ;decompress the level to the data area
  call initiatelevel
  call DrawLine         ;draws the horizontal line above the blocks
  call drawblox         ;draw all of the initial blox onto the screen
  call show_score
  call dpaddle          ;draw the paddle
  
  ld b,$ef              ;a short delay
wait2_:
  dec a                 
  jr nz,wait2_
  djnz wait2_
  
  call enter_pause

main:
  ld a,%00111110        ;keypress mask
  out (1),a             ;keypad port, usually people put a few 'nop' 
  in a,(1)              ;commands in here, but i dont care.
  bit 4,a
  jp z,teacher          ;jump to quick quit
  bit 7,a
  call z,enter_pause    ;pause till 2nd is pushed
  bit 6,a               ;test for key exit
  jp z,exit_key
  bit 2,a               ;test for key right
  ld c,a                ;preserve the keypress results in A
  call z,p_right
  ld a,c                ;restore the results from the keyport 
  bit 1,a               ;test for key left
  call z,p_left

  call dpaddle
  call ProcessBallz     ;The magic happens here
  
  call drawblox
  call PutBall          ;clear the old one, draw the new one
  call HandleBoni       ;the plural of Bonus... haha
  
  ld a,(dead)           ;check the dead flag for a death
  cp 1
  call z,died
  
selfmodify:
  nop
  nop
  nop
  ld a,(delayt)
  ld c,a
  ld b,10
dalay:
  dec a
  jr nz,dalay
  ld a,c
  djnz dalay
  
skipdelay:
  jp main

p_right:
 ld a,(x)
 inc a                  ;this command increases the A register hehe
 inc a
 ld b,a
 ld a,(p)
 or a
 ld a,b
 jr z,short
 cp 97
 ret nc
 jp good
short:
 cp 113
 ret nc 
good:
 ld b,a
 ld a,c
 bit 3,a
 jr nz,noup
 dec b
noup: 
 ld a,b
 ld (x),a
 ret

p_left:
 ld a,(x)
 cp 2
 ret c
 dec a
 dec a
 ld b,a
 ld a,c                 ;the keypress mask
 bit 3,a
 jr nz,noleft
 inc b
noleft: 
 ld a,b
 ld (x),a
 ret 

PutBall:
 ld hl,$cc80
 ld de,$cc81
 xor a
 ld (hl),a
 ld bc,320-1
 ldir                   ;clear the NO-MANS-LAND
 ld hl,$fe80
 ld de,$fe81
 xor a
 ld (hl),a
 ld bc,320-1
 ldir                   ;clear the NO-MANS-LAND
 
 ld de,$fc00            ;oh yea, this is stupid 
 call ball_draw_stuff   ;its not a grayscale routine so I have 
 ld de,$ca00            ;to draw it twice to each of the
 call ball_draw_stuff   ;bitmapped areas
 ret

ball_draw_stuff:        ;This draws a 3x3 block of ON pixels non-alligned
 ld hl,balla+2
 ld b,(hl)
 inc hl
 ld c,(hl)
 dec b
 call Find_Pixel
 add hl,de
 ld d,a
 ld c,3
PB_col: 
 push af
 push hl
 ld b,3
PB_row: 
 ld e,a
 or (hl)
 ld (hl),a
 ld a,e
 rrca                   ;rotate right branch carry
 jp nc,SB
  inc hl                ;No carry? then dont change bytes
SB:                     ;Same byte
 djnz PB_row            ;do this three times
 pop hl
 ld a,16
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 pop af
 dec c
 jr nz,PB_col
 ret

;PutPixel:
; call Find_Pixel
; ld de,(PS_addy)
; add hl,de
; or (hl)
; ld (hl),a
; ret

dpaddle:
 call clear_old
 ld a,(p)
 or a
 jr z,shortpaddle
 ld hl,x
 ld b,(hl)
 ld hl,bpaddle
 ld de,$fc00

 ld c,60
 push bc
 call SDR16
 ld de,$ca00
 ld hl,bpaddle2
 pop bc
 call SDR16
 ret

shortpaddle: 
 ld hl,x
 ld b,(hl)
 ld hl,paddle
 ld de,$fc00
 ld c,60
 push bc
 call SDR16
 ld de,$ca00
 ld hl,paddle2
 pop bc
 call SDR16
 ret

clear_old:
 push bc
 ld hl,$ca00+(16*60)
 ld de,$ca00+(16*60)+1
 xor a
 ld (hl),a
 ld bc,64
 ldir
 ld hl,$fc00+(16*60)
 ld de,$fc00+(16*60)+1
 xor a
 ld (hl),a
 ld bc,64
 ldir
 pop bc
 
  ld a,(flag)
  or a
  ret z
  dec a
  jr z,wall_one
  
   ld a,$FF
   jr lina
wall_one:  
   ld a,%10101010
lina:  
   ld b,8
   ld hl,$FFF0
lina_loop:
   ld (hl),a
   inc hl
   ld (hl),a
   inc hl
   djnz lina_loop
   ret

DrawLine:
 ld hl,$fc70            ;draw a single horizontal line, 7 down
 ld b,8
 ld a,255
DL_LOOP:
 ld (hl),a
 inc hl
 ld (hl),a
 inc hl
 djnz DL_LOOP
 ret

ProcessBallz:           ; UP/DO    SC     X    Y
  ld a,(switch)
  xor 1
  ld (switch),a
  
  
  ld ix,balla
  call ball_test
  call paddle_test
  call test_death
  
  ld ix,balla+4
  xor a
setup_dead:             ;sets up the dead flag
  add a,(ix)
 ; add a,(ix+5)         ;for when there are three ballz
 ; add a,(ix+10)        ;not yet implemented
  ld (dead),a
  ret

ball_test:  
  ld a,(ix)             ;UP/DO
  ld b,(ix+2)           ;X
  ld c,(ix+3)           ;Y

test_vertical:
  add a,c
  sub 7
  ld c,a
  or a
  jr z,not_clear_up
  call get_block_type
  or a
  jr z,its_clear_v      ;it was clear vertically

not_clear_up:  
  call maybe_clear_brick
  
  ld a,(ix)             ;it wasnt clear vertically
  neg 
  ld (ix),a
  
  jr test_horizontal
its_clear_v:
  ld a,(ix)
  add a,(ix+3)
  ld (ix+3),a
  ;jp test_horizontal

test_horizontal:
  ld a,(ix+1)
  ld b,(ix+2)          ;X  
  ld c,(ix+3)

  cp 0
  jr z,fine_scale
  jp p,movingright
  inc a
  or a
  jr nz,fine_scale
  ld a,(switch)
  dec a
  jp fine_scale

movingright:
  dec a
  or a
  jr nz,fine_scale
  ld a,(switch)

fine_scale:  
  ld (temp),a
  add a,b
  cp 127
  jr nc,switch_horiz  
  cp 1
  jp m,switch_horiz

  ld a,(ix+3)
  ld a,c
  sub 7
  ld c,a
  ld a,(temp)
  add a,(ix+2)
  ld b,a
  call get_block_type
  or a
  jr nz,switch_horiz
  
  ld a,(temp)           ;X
  add a,(ix+2)          ;scale
  ld (ix+2),a           ;X+scale
  ret

switch_horiz:
  ld a,(ix+1)
  neg
  ld (ix+1),a
  
  ld a,(hl)             ;if its cleared, then dont clear brick
  or a          
  ret z

  call maybe_clear_brick
  ret                   ;dont change this to jp cause it might not finish
                        ;It will screw up the ret command if you do
maybe_clear_brick:      
  cp 3                  ;check if its a solid
  ret z
  
  dec a                 ;this is still the value from 'maybe_c...'
  ld (hl),a
  ret nz                ;if the block didnt dissapear, then dont decrease the
  ld hl,(score)
  ld a,(much)
  add a,a               ;much*8
  add a,a
  add a,a
  add a,50
  add a,l
  ld l,a
  adc a,h               ;add HL+A
  sub l
  ld h,a
  ld (score),hl
  call show_score
  
  ld hl,much
  inc (hl)
  
  ld hl,bonusHL         ;test the Bonus flag, we dont want to give a bonus
  ld a,(hl)             ; if one exists allready
  inc hl
  ld d,(hl)
  or d
  jr nz,no_bonus 

  ld a,r
  and %00011110         ;a 1 in 16 chance of getting a bonus I think...
  rra
  or a
  jr z,dobonus1
  dec a
  jr z,dobonus2
  dec a
  jr z,dobonus3
  dec a
  jr z,dobonus4
  jr no_bonus
dobonus4:
  ld hl,bonus4
  ld e,3
  jr obonus
dobonus3:
  ld hl,bonus3
  ld e,2
  jr obonus
dobonus2:
  ld hl,bonus2
  ld e,1
  jr obonus
dobonus1:
  ld hl,bonus1
  ld e,a                ;ld e,0  <a=0>

obonus:
  ld a,e                ;setting up the proper operands for the bonus
  ld (bonusTY),a        ;handling...
  ld (bonusSP),hl       ;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ld hl,balla+2         ;Support the Zapata movement in Mexico!!
  ld b,(hl)             ;http://members.xoom.com/grchs
  inc hl                ;=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
  ld c,(hl)
  call Find_Pixel
  ld (bonusHL),hl
  ld a,l
  and 15
  ld (bonusW),a

  
no_bonus:               ;done with handling bonuses
  ld a,(blocks)         ;counter that says how many blocks to go.
  dec a
  or a
  jr z,newlevel         ;If that was the last block, then go to the nextlevel
  ld (blocks),a
  ret

newlevel:
  xor a                 ;reset the paddle
  ld (p),a
  ld (flag),a

  ld a,(level)
  inc a
  cp 9                  ;There exist only 8 levels, so its hard to go to 9...
  jp z,finished
  ld (level),a
  call unpacklevel      ;you dont want to unpack at death
notdead:  
  
  call initiatelevel
  call clear_old
  call drawblox
  call PutBall
  call DrawLine
  call dpaddle
  call show_score
  pop hl                ;maybe..   
  pop hl                ;ball_test
  jp enter_pause
  
get_block_type:
  ld a,c
  cp 32
  jp nc,off_array
  srl c
  srl c
  ld l,c
  ld h,0
  add hl,hl
  add hl,hl
  add hl,hl
  add hl,hl
  srl b
  srl b
  srl b
  ld e,b
  ld d,0
  add hl,de
  ld de,data
  add hl,de
  ld a,(hl)
  ret
off_array:
 xor a
 ret

enter_pause:
 ld hl,e_pause
 ld de,$3031
 ld (_penCol),de
 call _vputs
e_p:
 halt
 ld a,%00111111
 out (1),A
 nop 
 nop
 in a,(1)
 bit 5,a
 jr nz,e_p
 ret

HandleBoni:             ;handle the bonuses
  ld hl,bonusHL
  ld a,(hl)
  inc hl
  ld d,(hl)
  or d
  ret z                 ;If this location equals zero, then there 
                        ;are no boni (plural of...)
  
  ld hl,(bonusSP)
  ld d,h
  ld e,l
  ld hl,(bonusHL)
  ld bc,$ca00
  add hl,bc
  call copyb            ;Draw the corresponding bonus
  ld hl,(bonusHL)
  ld a,h
  or $FC
  ld h,a
  call copyb
  
  ld a,(bonusTIME)      ;after it has been redrawn, check if its time
  inc a                 ;to change the coordinates
  and %00000001
  ld (bonusTIME),a
  or a
  ret nz
 
  ld hl,(bonusHL)
  ld bc,16
  add hl,bc
  ld (bonusHL),hl
  ld a,h
  cp $03
  ret nz

CheckB:                 ;check if the paddle has hit a bonus
  ld a,l
  cp $d0
  jr c,On_
  
GenocideBonus:
  ld hl,0
  ld (bonusHL),hl
  ret

On_:  
  cp $a0
  ret c
  
  ld a,(p)
  or a
  jr z,checksmall
checkbig:
  ld e,4
  jr cc
checksmall:  
  ld e,2
cc:                     ;continue check
  ld hl,x
  ld c,(hl)
cc2:  
  ld a,c
  srl a
  srl a
  srl a
  ld b,a
  ld a,(bonusW)
  cp b
  jr z,HitBonus
  dec e
  jr z,lastcheck
  
  ld a,c
  add a,8
  ld c,a
  jr cc2

lastcheck:
  ld a,c
  add a,7
  srl a
  srl a
  srl a
  ld b,a
  ld a,(bonusW)
  cp b
  ret nz                ;if it wasnt a hit, return empty handed =(

HitBonus:
  ld a,(bonusTY)
  or a
  jr z,Make1
  dec a
  jr z,Make2
  dec a
  jr z,Make3
  dec a
  jr z,Make4

Make1:
  ld a,(lives)          ;extra life
  inc a
  ld (lives),a
  call show_lives
  jp GenocideBonus

Make2:  
  ld hl,(score)         ;extra 50 points
  ld c,50
  ld b,a
  add hl,bc
  ld (score),hl
  call show_score
  jp GenocideBonus

Make3:
  ld a,2
  ld (flag),a
  jp GenocideBonus
  
Make4:
  ld a,1
  ld (p),a
  ld a,(x)
  cp 96
  jp m,GenocideBonus
  ld a,95
  ld (x),a
  jp GenocideBonus

copyb: 
 ld b,4
copyloop:
 ld a,(de)
 ld (hl),a
 inc de
 ld a,16
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 djnz copyloop
 
 ret





paddle_test:
 ld a,(ix+3)
 cp 58
 jr z,pt_1
 cp 59
 jr z,pt_1
 cp 60
 jr z,pt_1
 ret                    ;if its not at the paddle's height, dont do this
pt_1:
 ld a,(p)
 or a
 jr nz,big_ass_paddle
normal_paddle:
 ld hl,x                ;paddles X location
 ld a,(hl)
 ld b,(ix+2)            ;ballz X position
 cp b
 ret nc
 add a,15
 cp b
 ret c                  ;make sure the ball is somewhere over the paddle
 sub 15
 ld c,a                 ;switch A&B using C
 ld a,b
 ld b,c
 sub b                  ;find the difference, put that in 'A' register
 add a,a
 ld hl,move_table
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 ld a,(hl)
 ld (ix+1),a
 ld a,-1
 ld (ix),a
 xor a
 ld (much),a
 ret

big_ass_paddle: 
 ld hl,x                ;paddles X location
 ld a,(hl)
 ld b,(ix+2)            ;ballz X position
 cp b
 ret nc
 add a,30
 cp b
 ret c                  ;make sure the ball is somewhere over the paddle
 sub 30
 ld c,a                 ;switch A&B using C
 ld a,b
 ld b,c
 sub b                  ;find the difference, put that in 'A' register
 ld hl,move_table
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 ld a,(hl)
 ld (ix+1),a
 ld a,-1
 ld (ix),a
 xor a
 ld (much),a
 ret

test_death
 ld a,(ix+3)
 cp 62
 ret nz
                        ;ball is too low, so it is dead
 
 ld a,(flag)
 or a
 jr z,no_save_wall
 dec a
 ld (flag),a
 ld a,(ix)
 neg
 ld (ix),a
 ret

no_save_wall: 
 ld a,1
 ld (ix+4),a
 ret


unpacklevel:
  ld a,(savedgame)
  or a
  jr z,normal_start
  
  ld hl,savedscore
  ld de,_textShadow
  ld bc,4
  ldir
  ld hl,savedgame
  xor a
  ld (hl),a
  inc hl
  jr saved_start
normal_start:  
  ld a,(level)          ;what level are you on?
  ld b,a
  ld hl,leveldata-32    ;all the compressed level data
  ld de,32
getaddy:
  add hl,de             ;add 32 for every level youre on
  djnz getaddy
  
saved_start:
  ld b,32               ;Copy the map + count blocks
  ld de,data
set_up_1:
  ld c,(hl)
  rlc c
  rlc c
  ld a,c
  and 3
  ld (de),a
  inc de
  rlc c
  rlc c
  ld a,c
  and 3
  ld (de),a
  inc de
  rlc c
  rlc c
  ld a,c
  and 3
  ld (de),a
  inc de
  rlc c
  rlc c
  ld a,c
  and 3
  ld (de),a
  inc de
  inc hl
  djnz set_up_1

count_blocks:
  ld hl,blocks
  xor a
  ld (hl),a
  ld de,data
  ld b,128
count_loop:
  ld a,(de)
  dec a
  jr z,increase_blocks
  dec a
  jr nz,skip_increase
increase_blocks:
  inc (hl)
skip_increase:
  inc de
  djnz count_loop
  ret

drawblox:
 ld b,128
 xor a
bloxloop
 ld c,a
 push bc
 call DrawA
 pop bc                 ;dont wanna mess up the counter
 ld a,c
 inc a
 djnz bloxloop
 ret

DrawA:
 ld b,a                 ;type
 rrca
 rrca
 rrca
 rrca
 and %00001111
 ld l,0                 ;\
 rra
 rr l                   ;   \
 rra                    ;   / Multiply A by 64, and store into HL
 rr l           
 ld h,a                 ;/
 ld a,b
 and 15                 ;add hl,A
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 ld a,128
 add a,l
 ld l,a
 adc a,h
 sub l
 ld h,a
 ld e,b                 ;add data,block number
 ld d,0
 ld bc,data
 ex de,hl
 add hl,bc
 ex de,hl
 ld a,(de)
 or a
 jp z,zero_
 dec a 
 jp z,one_
 dec a
 jp z,two_
 
 jr three_
zero_:
 ld de,16
 ld bc,$ca00
 push hl
 add hl,bc
 ld a,0
 ld (hl),a
 add hl,de
 ld (hl),d
 add hl,de
 ld (hl),d
 add hl,de
 ld (hl),d
 pop hl
 ld a,h
 or $FC
 ld h,a
 ;add hl,bc
 xor a
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 ret

two_
 ld de,16
 ld bc,$ca00
 push hl
 add hl,bc
 ld a,255
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 pop hl
 
 ld a,h
 or $FC
 ld h,a
 ;ld bc,$FC00
 ;add hl,bc
 
 ld a,255
 ld (hl),a
 add hl,de
 ld a,%11000011
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld a,255
 ld (hl),a
 ret

one_
 ld de,16
 ld bc,$ca00
 push hl
 add hl,bc
 ld a,%11111110
 ld (hl),a
 add hl,de
 ld a,%10000000
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 xor a
 ld (hl),a
 pop hl
 
 ld a,h
 or $FC
 ld h,a
 ;ld bc,$FC00
 ;add hl,bc
 
 ld a,%00000001
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld a,$ff
 ld (hl),a
 ret

three_
 ld de,16
 ld bc,$ca00
 push hl
 add hl,bc
 ld a,255
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 pop hl
 
 ld a,h
 or $FC
 ld h,a
 ;ld bc,$FC00
 ;add hl,bc
 ld a,$FF
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 add hl,de
 ld (hl),a
 ret

initiatelevel:
;set up some initial variables
  ld a,55
  ld (x),a
  ld hl,$fc00
  ld (PS_addy),hl
  ld a,1
  ld (ballz),a          ;how many balls??
  
  ld a,-1               ;this shit will set up the first freakin ball
  ld hl,balla
  ld (hl),a             ;load into UP/DOWN 0
  inc hl
  ld a,1                ;scale
  ld (hl),a
  ld a,65
  inc hl                ;load into X 65
  ld (hl),a
  ld a,58
  inc hl                ;load into Y 58
  ld (hl),a
  
show_lives:
  ld hl,$0035
  ld (_penCol),hl
  ld de,lnumber+1
  ld a,(lives)
  ld l,a
  ld h,0
  ld b,2
shw_l:
  call _divHLby10
  add a,'0'
  ld (de),a
  dec de
  djnz shw_l
  ld hl,msglives
  jp _vputs

show_score:  ld hl,0
  ld (_penCol),hl
  ld hl,(score)
  ;jp d_zm_deci        ;display the score real quick

D_zm_deci:              ;remember to set (penCol) and (penRow)
d_zm_deci: 
 ld de,number+4
 ld b,5
zm_hl:
 call _divHLby10
 add a,'0'
 ld (de),a
 dec de
 djnz zm_hl
 ld hl,current_score
 call _vputs
 ret

cbuffer:
  xor a
  ld hl,$ca00           
  ld de,$ca01
  ld (hl),a
  ld bc,$400-1
  ldir
  ret

.include sdr16.inc

offsets_table: .db 128,64,32,16,8,4,2,1

Find_Pixel:             ;This is an edited EBLE-YOPP routine
  push bc
  push de               ;faster than the eble yopp routine by 04 t-states       
  
  ld de,offsets_table
  ld a,b                 
  and %00000111          
  add a,e                        
  ld e,a                ; Apply changes to L
  adc a,d               ; Adds the carry flag. 
  sub e                 ; Subtracts L
  ld d,a                ; Apply changes to H
                      
  ld hl,FP_RLD          ; HL points to FP_RLD
  ld (hl),c             ; FP_RLD = Y
  ld a,b                ; A = X
  rra                   ; /2
  rra                   
  rra                   ; /8
  rld                   
  and %00000011   
  ld l,(hl)                             
  ld h,a           
  ld a,(de)       
  pop de
  pop bc
  ret                   ; holy ... that was fast..

finished:
  im 1
  call _clrLCD
  ;ei            
  
  ld a,(lives)          ;give points for extra lives remaining
  srl a
  ld d,a
  ld e,0
  ld hl,(score)
  add hl,de
  ld (score),hl

  ld hl,$0102
  ld (_curRow),hl
  ld hl,sFinal
  call _puts
  call e_p  
  pop hl                        ;the other day i was at the skate park...
  pop hl
  jr exit_dead
died:
  xor a
  ld (p),a
  
  ld a,(lives)
  dec a
  cp 0
  jr z,exit_dead
  ld (lives),a
  xor a
  ld hl,balla+4
  ld (hl),a
  push hl 
  push hl
  jp notdead
exit_dead:
   pop hl
exit_key:  
  call CloseGray        
  ld a,($C008)
  out (2),a
  ei                    ;this seems to effect the ending sequence
  xor a
  ld (savedgame),a
  ld hl,(highscore)
  ld de,(score)
  or a
  sbc hl,de
  jr nc,leave                ;exit the game completely
  ld hl,(score)
  ld (highscore),hl
leave:
  ld hl,progname-1
  rst 20h
  rst 10h
  ex de,hl              ;set up AHL results of FIND_SYM
  ld a,b
  ld de,highscore-_asm_exec_ram+4
  add hl,de             ;add AHL,DE
  adc a,0
  ld de,highscore
  ld b,28               ;bytes to store this also overwrites the saved flag
  call RepCopy          ;It doesnt matter if it overwrites stuff after that
  
 ;----CLEAN UP----
  set 1,(iy+$0d)
  call _clrScrn
  call cbuffer
backtotheshellassemblygame ;go back to the shell you crazy game  
  ret

RepCopy:
  push af
  push hl
  call $46C3            ; if you must know... this turns AHL into asic
  ld a,(de)             ; There exist another RomCall that is specifically
  ld (hl),a             ; for converting ABS pointers to ASIC, but i didnt
  pop hl                ; feel like finding it, cause i really dont care ;)
  pop af
  call $4637
  inc de
  djnz RepCopy
  ret                                                                     

teacher:
  call CloseGray
  ld a,($C008)
  out (2),a
  ei
  ld hl,savedgame
  ld a,1
  ld (hl),a
  inc hl
  ld de,data
  ld b,32
compress:
  push bc
  ld c,0
  ld b,4
compress2:
  rlc c
  rlc c
  ld a,(de)
  or c
  ld c,a
  inc de
  djnz compress2
  ld (hl),c
  inc hl
  pop bc
  djnz compress
  ex de,hl
  ld hl,_textShadow
  ld bc,4
   ldir
  ld hl,progname-1
  rst 20h
  rst 10h
  ex de,hl              ;set up AHL results of FIND_SYM
  ld a,b
  ld de,savedgame-_asm_exec_ram+4
  add hl,de             ;add AHL,DE
  adc a,0
  ld de,savedgame
  ld b,37               ; bytes to store
  call RepCopy          ;copy bytes from de to AHL until B=0

  set 1,(iy+$0d)
  call _clrScrn
  call cbuffer
  call $4a95
  jp _jforcecmdnochar

fixself:  
  xor a
  ld b,3
  ld hl,selfmodify
fixs:  
  ld (hl),a
  inc hl
  djnz fixs
  ret

leveldata           ;there are eight 

  .db %00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000000,%00000000,%00000000
  .db %00010101,%01010101,%01010101,%01010100
  .db %00010101,%01010101,%01010101,%01010100
  .db %00000000,%00000000,%00000000,%00000000
  .db %00001010,%00000010,%10000000,%10100000
  .db %00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000000,%00000000,%00000000
  
  .db %00000000,%00000000,%00000000,%00000000
  .db %00010001,%00010001,%00010001,%00010001
  .db %01000100,%01000100,%01000100,%01000100
  .db %00010001,%00010001,%00010001,%00010001
  .db %01000100,%01000100,%01000100,%01000100
  .db %00010001,%00010001,%00010001,%00010001
  .db %00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000000,%00000000,%00000000

  .db %11110000,%00000000,%00000000,%00001111
  .db %11000101,%01000000,%00000001,%01010011
  .db %00000101,%01000101,%01010001,%01010000
  .db %00000101,%01000111,%11010001,%01010000
  .db %00000101,%01000111,%11010001,%01010000
  .db %00000000,%00000101,%01010000,%00000000
  .db %00000000,%00000000,%00000000,%00000000
  .db %00000000,%00000000,%00000000,%00000000
  
  .db %01010101,%00100001,%01010001,%01010100
  .db %01010101,%00100001,%00010001,%00000100
  .db %00010100,%00100001,%00010001,%00000000
  .db %00010100,%00100001,%11010001,%01010100
  .db %00010100,%00100001,%00010001,%00000100  ;ti86
  .db %00010100,%00100001,%00010001,%00000100
  .db %00010100,%00100001,%00010001,%00000100
  .db %00010100,%00100001,%01010001,%01010100

  .db %11111101,%00000000,%00000000,%01111111
  .db %11110101,%00000000,%00000000,%00011111
  .db %11010000,%00000001,%01000000,%00000111
  .db %00000000,%00010100,%00010100,%00000000
  .db %00000000,%01000000,%00000001,%00000000
  .db %00000000,%01000000,%00000001,%00000000
  .db %00000000,%00010100,%00010100,%00000000
  .db %00000000,%00000001,%01000000,%00000000

  .db %01010100,%11110000,%00001111,%00010101
  .db %01010100,%11000000,%00000011,%00010101
  .db %01010100,%11000000,%00000011,%00010101
  .db %01010100,%00000000,%00000000,%00010101
  .db %01010100,%00000000,%00000000,%00010101
  .db %01010100,%00000000,%00000000,%00010101
  .db %01010100,%00000000,%00000000,%00010101
  .db %11111111,%11000000,%00000011,%11111111
                              
  .db %01000000,%11110001,%01000000,%01010000
  .db %01000000,%11110001,%01000000,%01010000
  .db %01000100,%00000001,%01000000,%01010000
  .db %01010000,%01010001,%01000000,%01010000
  .db %01010000,%01010001,%01000000,%01010000
  .db %01000100,%01010001,%01000000,%01010000
  .db %01000100,%01010001,%01010100,%01010101
  .db %01000000,%01010001,%01010100,%01010101

  .db %01010101,%00000000,%00000001,%01010000
  .db %01010101,%00010100,%00000001,%01010100
  .db %01000000,%00010101,%01000001,%00000101
  .db %01000000,%00010100,%01000001,%00000101
  .db %01010100,%00010100,%01000001,%00000101
  .db %01000000,%00010100,%01000001,%00000101
  .db %01010101,%00010100,%01000001,%01010100
  .db %01010101,%00010100,%01000001,%01010000

paddle:
  .db 2,4
  .db %01111111,%11111110               ;bitmap for normal paddle
  .db %11000000,%00000011               ;kinda dark
  .db %11111111,%11111111               ;kinda dark
  .db %01111111,%11111110
paddle2:
  .db 2,4
  .db %01111111,%11111110               ;really light
  .db %10111111,%11111101
  .db %10000000,%00000001
  .db %01111111,%11111110

bpaddle:
  .db 4,4
  .db %01111111,%11111111,%11111111,%11111110
  .db %10000000,%00000000,%00000000,%00000001
  .db %11111111,%11111111,%11111111,%11111111
  .db %01111111,%11111111,%11111111,%11111110
bpaddle2:
  .db 4,4  
  .db %01111111,%11111111,%11111111,%11111110
  .db %11111111,%11111111,%11111111,%11111111
  .db %10000000,%10000000,%00000000,%00000001
  .db %01111111,%11111111,%11111111,%11111110

bonus1:                 ;extra vida
  .db %01111110
  .db %11000011
  .db %01111110
  .db %00000000
  .db %01111100
  .db %10000001
  .db %01111110
  .db 0


bonus2:                 ;50 points
  .db %11110010
  .db %11000101
  .db %00110101
  .db %11100010
  .db %11110010
  .db %11000101
  .db %00110101
  .db %11100010


bonus3:                 ;invisible wall
  .db %11000011
  .db %00111100
  .db %00111100
  .db %11000011
  .db %11000011
  .db %00111100
  .db %00111100
  .db %11000011

bonus4:                 ;friggin wide paddle
  .db %00100100
  .db %01000010
  .db %11111111
  .db %01000010
  .db %00100100
  .db %01000010
  .db %11111111
  .db %01000010
 
move_table:             ;32 different because the big paddle is 32 wide
 .db      -3,-3
 .db      -2,-2,-2,-2,-2,-2
 .db      -1,-1,-1,-1,-1,-1
 .db      0,0,0,0                     ;dont ask
 .db      1,1,1,1,1,1
 .db      2,2,2,2,2,2
 .db      3,3


Author          .db "by: James Rubingh",0
progname        .db 8,"Arkanoid"             ;for the addressing 
arktitle:       .db 8,"arktitle"
current_score:  .db "Score: "
number:         .db 0,0,0,0,0,0          ;for putting numbers on screen
msglives:       .db "Lives: "            
lnumber:        .db 0,0,0                ;Only double digits, then a null
choosespeed:    .db "Select Speed F1- F5",0
e_pause:        .db "Press 2nd",0
sFinal:         .db "Thats It, You Win!",0
hightext:       .db "High",0               
TITLE:          .db "Arkanoid v1.0",0

;-----Stuff that stays the same when you exit
highscore:      .dw 0                 
Title           .db "Arkanoid v.8 ACZ",0
savedgame:      .db 0                    ;saved game data

  .db 0,0,0,69,0,0,0,0,0,0,0,0,0,0,0,0
  .db 0,0,0,0,2,0,0,0,0,0,0,0,0,0,0,0

savedscore:     .dw 420  ;also the saved lives, level
                .dw 0
.include gray.h          ;grayscale IM 2 routines by Dux Gregis
                         ;thanks Dux, you are the man
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
;    James Rubingh  James@acz.org (ephesus@gmail.com)
; http://members.tripod.com/~jaymzroo
;       AOL_SN:power2ezln
;  ACZ member -Assembly Coders Zenith-
;-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
 
;  Please share if you think there are any ways to optimize this. 
 
 .end
