org 0x100

x2        equ   0x900

init:

  ; setup gfx
	mov al, 0x13
	int 0x10
	xchg bp, ax
	push 0xa000
	pop es

top:
	mov ax, 0xcccd
	mul di  ; dh: y coord, dl: x coord + carry

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
  jl .skip

  shr ax, 5  ; ofx = (x2-x1)/32
  cmp al, 47
  jg restart

  ;xor ah, ah
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

  dec bp

  cmp bp, 0xf9b0
  jg .skip

  jmp short quit

.skip:

restart:
  inc di
  jne top

quit:
  ret

palette:
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
