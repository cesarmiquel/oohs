org 0x100

%define tempo 50

x2        equ   0x900
incx      equ   0x902
count     equ   0x903

;initial_time    equ 0xffc0
initial_time    equ 260
final_time      equ 0x86

init:

  ; setup gfx
	mov al, 0x13
	int 0x10
	xchg bp, ax
	push 0xa000-10
	pop es

  ; setup dos timer
  mov ax, 0x251c
	mov dx, timer
	int 0x21

  ; DELETE
  mov bp, initial_time
  ;mov di, 0

top:
	mov ax, 0xcccd
	mul di  ; dh: y coord, dl: x coord + carry

  mov byte [palidx+2], 0

  ;cmp dh, 64
  ;je draw
  ;cmp dh, 64+32
  ;je draw
  ;cmp dh, 64+32*2
  ;je draw
  ; draw only lines in 0x40, 0x60, 0x80
  mov al, dh         ; 2 bytes
  cmp al, 64+32*3+1
  ja blit
  rol al, 3          ; 3 bytes  40h->02h, 60h->03h, 80h->04h
  sub al, 2          ; 2 bytes  -> 0, 1, 2
  cmp al, 2          ; 2 bytes
  jbe draw           ; 2 bytes  unsigned: AL <= 2

  mov si, di
  sub si, 320
  mov cl, 80
  cld
  es rep movsw
  ja top

draw:
  shr dh, 5 ; row - y/32
  sub dh, 2 ; row - 2

  ; 0 <= row < 3
  jl blit
  cmp dh, 2
  jg blit

  ; load si with pointer to font row
  mov si, fptext
  xor ax, ax
  mov al, dh
  mul ax, 6   ; row * 6
  add si, ax

  ; save x and init x2
  mov al, dl
  cbw ; convert 8-bit negative to 16-bit negative (ax)
  mov word [x2], ax
  sar dl, 3  ; shift right and preserve sign
  mov byte [incx], dl
  mov byte [count], 1

loop:
  mov ax, word [x2]
  sub ax, bp
  ;sub ax, -80
  jl .skip

  shr ax, 5  ; ofx = (x2-x1)/32
  mov cx, ax
  shr ax, 3  ; pos = ofx/8
  cmp al, 5
  jg restart

  xchg bx, ax

  xor ah, ah
  mov al, byte [si+bx]
  and cl, 0x07
  shl al, cl
  jnc .skip

  mov cl, byte [count]
  or byte [palidx+2], cl

.skip:
  mov al, byte [incx]
  cbw
  add word [x2], ax

  shl [count], 1
  cmp [count], 0x10
  jne loop

blit:
  mov si, palette
palidx:
  add si, byte 0x2
  lodsb
	stosb
blit2:

  ; DELETE
;.loop
;  cmp di, 64*320 + 320*20
;  jg .loop

	inc di
	inc di
  jnz top

  ;sub bp, 5
  ;dec bp
  ;dec bp
  ;dec bp
 
; - stabilizes image a bit
;  mov dx, 3DAh
;.wait_start:
;  in al, dx
;  test al, 8
;  jz .wait_start     ; wait for new retrace to begin

  mov al, tempo
	out 40h, al
	in al, 0x60
	dec al
	jmp top

restart:
  jne blit

timer:
  dec bp

  cmp bp, 0xfa00
  jg .skip

  mov bp, initial_time

.skip:
%ifdef MUSIC
  ; Music
  mov cx, bp
  and cx, 0x7f
  jnz skip_play

  mov si, music
  mov dx, 0x330
  mov cl, 3
  rep  outsb
  inc dx
  outsb
%endif


skip_play:
  iret

palette:
  ;db 0, 124, 2, 50
  ;db 4, 25, 116, 71
  ;db 34, 79, 79, 76
  ;db 36, 60, 84, 15

  db 0
  db 3   ; l0
  db 124 ; l1
  db 52  ; l0+l1

  db 4   ; l2
  db 52  ; l0+l2
  db 27  ; l1+l2
  db 100 ; l0+l1+l2

  db 108 ; l3
  db 56  ; l0+l3
  db 79  ; l1+l3
  db 76 ; l0+l1+l3

  db 38  ; l2+l3
  db 60  ; l0+l2+l3
  db 84  ; l1+l2+l3
  db 15  ; l0+l1+l2+l3


fptext:
  db 0xe8, 0xec, 0xa0, 0xee, 0xee, 0xa0
  db 0xc8, 0xee, 0xe0, 0xee, 0xc4, 0xe0
  db 0x8e, 0xa6, 0xa0, 0x8a, 0xa4, 0x40

music:
  ;db 0xca  ; change instrument on channel 3
  ;db 39    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
  db 0x99  ; play note on channel 10
  db 35    ; deep "b" = note number 35
  db 127    ; play with volume = 127
  ;db 43    ; play with volume = 127
