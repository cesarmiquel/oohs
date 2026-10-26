org 0x100

%define tempo 30

x2        equ   0x900
incx      equ   0x902

initial_time    equ 260

init:

  ; setup gfx
	mov al, 0x13
	int 0x10
	xchg bp, ax
	push 0xa000
	pop es

  ; setup dos timer
  mov ax, 0x251c
	mov dx, timer
	int 0x21

  ; DELETE mov bp, initial_time

top:
	mov ax, 0xcccd
	mul di  ; dh: y coord, dl: x coord + carry

  ;cmp dh, 64
  ;je draw
  ;cmp dh, 64+32
  ;je draw
  ;cmp dh, 64+32*2
  ;je draw
  ;cmp dh, 64+32*3+1
  ;ja blit2

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
  mov cx, 320
  cld
  es rep movsb
  jmp short top

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
  xor al, 0x80
  cbw ; convert 8-bit negative to 16-bit negative (ax)
  mov word [x2], ax
  sar al, 3  ; shift right and preserve sign

  mov byte [incx], al

  mov dl, 1
  mov dh, 0

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

  mov cl, dl
  or dh, cl

.skip:
  mov al, byte [incx]
  cbw
  add word [x2], ax

  shl dl, 1
  cmp dl, 0x10
  jne loop

blit:
  mov bx, palette
  mov al, dh
  xlat
	stosb


  ; DELETE
;.loop:
;  cmp di, 64*320 + 320*20
;  jg .loop

	;inc di
	;inc di
  test di, di
  jnz top

; - stabilizes image a bit
  mov dx, 3DAh
.wait_start:
  in al, dx
  test al, 8
  jz .wait_start     ; wait for new retrace to begin

;  dec bp
  dec bp

  cmp bp, 0xf900
  jg .skip

  mov bp, initial_time

.skip:

  mov al, tempo
	out 40h, al
	in al, 0x60
	dec al
	jmp top

restart:
  inc di
  jne top

timer:
  pusha
;  dec bp
;
;  cmp bp, 0xf900
;  jg .skip
;
;  mov bp, initial_time
;
;.skip:

%ifdef MUSIC
  ; Music
  mov cx, bp
  and cx, 0x1f
  jnz skip_play

  ;mov [music + 2], di
  ;add [music + 3], 50
  ;and [music + 3], 0x3f

  mov dx, 0x330
  mov si, music
  mov cl, 5
  rep  outsb
  inc dx
  outsb
%endif

skip_play:
  popa
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

%ifdef MUSIC
music:
  ; single note
  ;db 0xc3  ; change instrument on channel 3
  ;db 26    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
  ;db 0x93  ; play note on channel 10
  ;db 30    ; deep "b" = note number 35
  ;db 127    ; play with volume = 127

  db 0xc0  ; change instrument on channel 3
  db 89    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
  ;db 0x90   ; play note on channel 10
  ;db 35   ; deep "b" = note number 35
  ;db 127    ; play with volume = 127
  db 0x99   ; play note on channel 10
  db 36   ; deep "b" = note number 35
  db 127    ; play with volume = 127

%endif
