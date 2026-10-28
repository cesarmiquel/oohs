org 0x100

%define tempo 30

x2        equ   0x900

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

  lea si, [di-320]
  mov cx, 320
  es rep movsb
  jmp short top

draw:
  mov dh, al

  ; load si with pointer to font row
  ;mov si, fptext
  mov ah, 0
  mul ax, 6   ; row * 6
  mov si, ax

  ; save x and init x2
  mov al, dl
  xor al, 0x80
  cbw ; convert 8-bit negative to 16-bit negative (ax)
  mov word [x2], ax
  sar al, 3  ; shift right and preserve sign

  mov dx, 1   ; dl loop counter, dh = 0 (idx)
  mov ch, al  ; x/8

loop:
  mov ax, word [x2]
  sub ax, bp
  ;sub ax, -80
  jl .skip

  shr ax, 5  ; ofx = (x2-x1)/32
  cmp al, 47
  jg restart

  xor ah, ah
  bt [si+fptext], ax
  jnc .skip

  or dh, dl

.skip:
  mov al, ch
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

%ifdef MUSIC
  ; Music
  mov dx, bp
  and dx, 0x07
  jnz skip_play

  ; unmute ch1 and ch2
  mov si, music
  mov byte [si+2], 127
  mov byte [si+5], 127

  rol byte [si + 6], 1
  jc skipmute1
  mov byte [si + 2], 0

skipmute1:
  rol byte [si + 7], 1
  jc skipmute2

  mov byte [si + 5], 0

skipmute2:
  xor byte [si + 4], 1
  ;mov [music + 3], di
  ;add byte [music + 3], ah
  ;and byte [music + 3], 0x3f
  ;xor [music + 3], 0x07

  mov dx, 0x330
  mov si, music
  mov cl, 6
  rep  outsb
  inc dx
  outsb
%endif

skip_play:
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
;  pusha
;  dec bp
;
;  cmp bp, 0xf900
;  jg .skip
;
;  mov bp, initial_time
;
;.skip:
;  popa
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


fptext:  ; pixel column k of each byte is bit k
  db 0x2e, 0x6e, 0x0a, 0xee, 0xee, 0x0a
  db 0x26, 0xee, 0x0e, 0xee, 0x46, 0x0e
  db 0xe2, 0xca, 0x0a, 0xa2, 0x4a, 0x04

;fptext:
;  db 0xe8, 0xec, 0xa0, 0xee, 0xee, 0xa0
;  db 0xc8, 0xee, 0xe0, 0xee, 0xc4, 0xe0
;  db 0x8e, 0xa6, 0xa0, 0x8a, 0xa4, 0x40

%ifdef MUSIC
music:
  ; single note
  ;db 0xc3  ; change instrument on channel 3
  ;db 26    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
  ;db 0x93  ; play note on channel 10
  ;db 30    ; deep "b" = note number 35
  ;db 127    ; play with volume = 127

  ;db 0xc0  ; change instrument on channel 3
  ;db 89    ; Instrument: https://en.wikipedia.org/wiki/General_MIDI#Sound_Effects
  ;db 0x90   ; play note on channel 10
  ;db 55   ; deep "b" = note number 35
  ;db 0    ; play with volume = 127

  ; Drum channel / K.O.II
  db 0x99   ; play note on channel 10 (drums)
  db 36
  db 110    ; play with volume = 127
  db 0x99   ; play note on channel 10 (drums)
  db 62
  db 110    ; play with volume = 127

pattern:
  db 0b10011000
  db 0b10101111

%endif
