.include crash82.inc
.db "THX 1138 82",0

;if you see any ways
;that this code could be optimized, please do so. Tell me if you can too,
;i would be interested to know what could have been done better.

SCORE = TEXT_MEM
x = TEXT_MEM+2
y = TEXT_MEM+3
d = TEXT_MEM+4
delayt = TEXT_MEM+5  
String = TEXT_MEM+6


  ROM_CALL(CLEARLCD)
  
  LD A, $8C               ; set to ROM page 4 for graphics
  OUT (2), A

  TEXT_START            ;check out crash82.inc, this sets text flags
                        ;dont effect text shadow and what-not
  ld bc,$0402
  ld hl,msgTITLE
  call DisplayStr       ;load BC into CURSOR_POS, D_ZT_STR
  ld bc,$0005
  ld hl,msgAUTHOR
  call DisplayStr

  call wait

  ROM_CALL(CLEARLCD)
  call init
  call drawfield

main:  
  halt
  call GET_KEY
nokeypress:  
  cp G_CLEAR
  jr z,EXIT
  cp G_UP
  jr z,go_up
  cp G_DOWN
  jr z,go_down
  cp G_LEFT
  jr z,go_left
  cp G_RIGHT
  jr z,go_right

  ld a,(d)
  jr nokeypress

EXIT: TEXT_END
  ret

go_right:
  ld (d),a
  ld hl,x
  inc (hl)
  jr kback

go_left:
  ld (d),a
  ld hl,x
  dec (hl)
  jr kback

go_up:
  ld (d),a
  ld hl,y
  inc (hl)
  jr kback

go_down:
  ld (d),a
  ld hl,y
  dec (hl)
  jr kback

kback: ;continue the main loop yo
testcrash:
  ld a,(x)
  ld b,a
  
  ld a,(y)
  ld c,a
  call GetPixel
  or a
  jr z,THE_FREAKING_PIXEL_IS_CLEAR

  ld bc,$0502
  ld hl,msgBoom
  call DisplayStr
  call wait
  ROM_CALL(CLEARLCD)

  ld hl,msgFinal
  ld bc,$0203
  call DisplayStr
  ld bc,$2222
  call DisplayScore
  
  
  ld hl,(SCORE)
  ex de,hl
  ld hl,(HighScore)
  or a
  sbc hl,de
  jr nc,noHigh
  ld (HighScore),de

noHigh:  

  ld hl,0
  ld (CURSOR_X),hl
  ld hl,msgHigh
  ROM_CALL(D_ZM_STR)
  ld hl,(HighScore)
  ld (SCORE),hl
  ld bc,15
  call DisplayScore
  ld bc,$3707
  ld (CURSOR_X),bc
  ld hl,msgPORT
  ROM_CALL(D_ZM_STR)
  
  call wait
  jp EXIT

THE_FREAKING_PIXEL_IS_CLEAR:  
  ld a,(x)
  ld b,a
  ld a,(y)
  ld c,a
  call PutPixel
  
  ld hl,(SCORE)
  inc hl
  ld (SCORE),hl
  
  ld bc,66
  call DisplayScore
  call delay
  jp main


drawfield:
  ld bc,$0003
  ld (CURSOR_X),bc
  ld hl,msgTITLE
  ROM_CALL(D_ZM_STR)

  ld b,96
vertical:       ;draws the horizontal lines
  ld c,0
  call PutPixel
  ld c,56
  call PutPixel
  djnz vertical
  ld c,56
horiz:  
  ld b,95
  call PutPixel
  ld b,0
  call PutPixel
  dec c
  jr nz,horiz
  call PutPixel
  ret

delay:
  ld a,(delayt)
  ld b,a
d1:
  dec a
  jr nz,d1
  dec b
  jr nz,d1
  ret

PutPixel:
  ld e,b
  ld d,c
  CALL FIND_PIXEL       ;graphics that arent sprites are easy as hell
  ld b,a                ;thats all i gotta say about this section
  ld a,($8011)          ;yes, i could add 20h or 80h and make a command
  call $7F3             ;OR I COULD LET FIND_PIXEL DO IT FOR ME!
  out ($10),a           ;ti-82s suck, buy a ti-86
  ld a,($800F)          ;then visit:
  call $7F3             ;http://members.tripod.com/~jaymzroo/phat.html
  out ($10),a           ;my page, the BOMM for 86s  muha haa haaa!
  call $7F3
  in a,($11)
  call $7F3
  in a,($11)
  or b
  ld b,a
  ld a,($8011)
  call $7F3
  out ($10),a
  ld a,($800F)
  call $7F3
  out ($10),a
  ld a,b
  call $7F3
  out ($11),a
  ld b,e
  ld c,d
  ret

GetPixel:
  CALL FIND_PIXEL       ;convert the x,y coordinates into commands to
  ld b,a                ;send to the display control port
  ld a,($8011)          ;get the command from here
  call $7F3
  out ($10),a
  ld a,($800F)          ;get the other command from here
  call $7F3             ;commands are actually the coordinate+20h=column
  out ($10),a           ;                          coordinate+80h=row 
  call $7F3
  in a,($11)
  call $7F3             ;then right before you do any writing or reading 
  in a,($11)            ;from or to the ports, you call a display delay
  and b                 ;mask out all bits except the one we want
  ret

wait:
  halt
  call GET_KEY
  or a
  jr z,wait
  ret

init:
  ld a,30
  ld (x),a
  ld (y),a
  ld a,G_RIGHT
  ld (d),a
  ld a,$20
  ld (delayt),a
  ret

DisplayStr:
  ld (CURSOR_POS),bc
  ROM_CALL(D_ZT_STR)
  ret

DisplayScore:
  ld hl,(SCORE)
  ld (CURSOR_X),bc
  ld b,5
  ld de,String+5
  xor a
  ld (de),a
  dec de
DO_THAT_CRAZY_THING_YO:
  call UNPACK_HL
  add a,'0'
  ld (de),a
  dec de
  djnz DO_THAT_CRAZY_THING_YO
  ex de,hl
  ROM_CALL(D_ZM_STR)
  ret


msgTITLE:  .db "Thx1138",0                      
msgAUTHOR:  .db "By Brandon Turok",0            
msgPORT:  .db "82 port by James Rubingh",0                    
msgBoom:  .db "Crash",0                         
msgFinal:  .db "Final Score:",0                 
msgHigh:  .db "High Score",0                    
                                               
HighScore:
.dw 0

;+--------------------------------------------------------------------+
;| James Rubingh  jaymzroo@juno.com                                   |
;|                ephesus@gmail.com                                   |
;|                jaymzroo@yahoo.com                                  |
;|         http://wrive.com                                           |
;|         http://members.tripod.com/~jaymzroo/phat.html              |
;+--------------------------------------------------------------------+
