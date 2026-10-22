org 0x100

%define targetFPS 35
%define tempo 1193182/1/targetFPS	

cur_x     equ   0x902
cur_y2    equ   0x903
intensity equ   0x904

initial_time    equ 0xffc0
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

top:
	mov ax, 0xcccd
	mul di  ; dh: y coord, dl: x coord + carry
  ;mov bx, dl
  ;shl bx, 3 ; bx = x / 8
  mov byte [idx+2], 0

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

loop:
  xchg al, dl
  cbw ; convert 8-bit negative to 16-bit negative (ax)
  mov dx, bp
  sub ax, dx
  ;mov ax, word 0x0
  ;xor dh, dh
  ;sub dx, ax
  cmp ax, 0

  jl blit

  ;mov byte [idx+2], 0xd

  shr ax, 4  ; ofx = (x2-x1)/32
  push ax
  shr ax, 3  ; pos = ofx/8
  ;cmp al, 5
  ;jg  skip

  ;  TODO: usar bx para despues hacer [si + bx]
  ;xor ah, ah
  add si, ax

  xor bh, bh
  mov bl, byte [si]
  pop cx
  and cx, 0x0007
  shl bl, cl
  jnc skip

  mov byte [idx+2], 0xf

skip:
  ; add dl, bx
  ; jnz loop

blit:
  mov si, palette
idx:
  add si, byte 0x2
  lodsb
	stosb
	inc di
	inc di
  jnz top
  mov al, tempo
	out 40h, al
	in al, 0x60
	dec al
	jnz top


timer:
  dec bp
  dec bp
  iret

palette:
  db 0, 124, 2, 50
  db 4, 25, 116, 71
  db 34, 79, 79, 76
  db 36, 60, 84, 15

fptext:
  db 0xe8, 0xec, 0xa0, 0xee, 0xee, 0xa0
  db 0xc8, 0xee, 0xe0, 0xee, 0xc4, 0xe0
  db 0x8e, 0xa6, 0xa0, 0x8a, 0xa4, 0x40

;music:
;  db 0xc3  ; change instrument on channel 3
;  db 49    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
;  db 0x93  ; play note on channel 3
;  db 10    ; deep "b" = note number 35
;  db 34    ; play with volume = 127
;  ;db 43    ; play with volume = 127
