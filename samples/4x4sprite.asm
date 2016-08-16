.include asm86.h
.include ti86asm.inc
.org _asm_exec_ram

; monochrome 4x4 sprite blitting z80 asm
; by James Rubingh james@wrive.com http://www.wrive.com

; IX = pointer to Sprite Data
; B  = X coordinate
; C  = Y coordinate   top left corner is 0,0

Draw4x4:
  ld h,%00111111	;calculate Offset
  ld a,c
  add a,a
  add a,a
  ld l,a
  ld a,b
  rra
  add hl,hl             ;x8
  rra                           ;\4
  add hl,hl             ;x16
  rra                           ;\8
  or l
  ld l,a
  ld a,b
  and 7
  ld bc,D4bits
  add a,c
  ld c,a
  adc a,b
  sub c
  ld b,a
  ld a,(bc)             ;HL = offset IX=ssprite data
  ld b,4
Vert:
  push bc
  push af
  push hl
  ld d,(ix)
  ld b,4
Horiz:
  ld e,a
  rl d
  jr c,Setpixel
  cpl
  and (hl)
  ld (hl),a
  jr incbyte
Setpixel:
  or (hl)
  ld (hl),a
incbyte:
  ld a,e
  rrca
  jr nc,SkipI
  inc hl
SkipI:
  djnz Horiz
  pop hl
  ld a,16
  add a,l
  ld l,a
  adc a,h
  sub l
  ld h,a
  inc ix
  pop af
  pop bc
  djnz Vert
  ret
D4bits:
  .db 128,64,32,16,8,4,2,1

.end

