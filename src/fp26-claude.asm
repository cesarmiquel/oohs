; fp26 - three bands of scrolling "FP" text in 4 parallax layers, with MIDI
; drums and a gated synth on the MPU-401 (port 0x330).
;
; Build: nasm fp26-claude.asm -fbin -O0 -DMUSIC -o fp26c.com  (223 bytes)
; Needs a 386+ (bt, jcc near) and uses the undocumented SALC instruction.
;
; Registers in the main loop:
;   es:di  screen pointer, one pixel per iteration; di wraps to 0 every frame
;   bp     time: decremented once per frame, scrolls the text, drives the music

org 0x100

init:
  mov al, 0x13          ; mode 13h: 320x200, 256 colours
  int 0x10
  xchg bp, ax           ; start time = whatever the BIOS left in ax
  push 0xa000
  pop es

; ---------------------------------------------------------------------------
; Start of each frame (di = 0 -> 1, the first pixel is never drawn), also
; where a pixel past the end of the text goes to be skipped.

restart:
  inc di

; ---------------------------------------------------------------------------
; Per pixel: split di into y and x.
; di * 0xcccd / 2^24 = di / 320, so dh = y and dl = (x mod 320) * 256/320.

top:
  mov ax, 0xcccd
  mul di                ; dh = y, dl = x * 0.8

  mov al, dh            ; al = y, also the palette index for rows > 0xa1
  cmp al, 0xa1          ; rows below the last band are not drawn or copied
  ja blit

  ; Only rows 0x40, 0x60 and 0x80 are rendered. rol 3 turns them into 2, 3, 4,
  ; so after subtracting 2 the band number 0..2 is the only result <= 2.
  rol al, 3
  sub al, 2
  cmp al, 2
  jbe draw

  ; Every other row is a copy of the row above it. cx ends up 0, which the
  ; music code below relies on.
  lea si, [di-320]
  mov cx, 320
  es rep movsb
  jmp short top

; ---------------------------------------------------------------------------
; Render one pixel of a text row: al = band (0..2), dl = x * 0.8.

draw:
  cbw
  imul ax, byte 6       ; 6 font bytes per band
  xchg si, ax           ; si = offset of this band's font row

  mov al, dl
  xor al, 0x80          ; centre x: -128..127, 0 in the middle of the screen
  cbw
  mov bx, ax            ; bx = x position in layer 0
  sar ax, 3
  xchg cx, ax           ; cx = x/8, how far each layer is displaced from the last

  mov al, 0x10          ; al collects one bit per layer; 0x10 is the end marker

; For each layer: text column = (x - time) / 32. Columns left of the text
; give a 0 bit; a column past the text skips the pixel entirely.
.layer:
  mov dx, bx
  add bx, cx            ; next layer, more parallax
  sub dx, bp
  jl .zero              ; left of the text

  shr dx, 5             ; dx = text column
  cmp dl, 47            ; 6 bytes * 8 columns
  jg restart            ; past the end: leave the pixel as it is

  bt [si+fptext], dx    ; CF = font pixel
  db 0xb4               ; mov ah, imm8: swallows the clc, keeps CF
.zero:
  clc
  rcl al, 1             ; shift the layer bit into the index
  jnc .layer            ; 4 layers, until the marker falls into CF

; ---------------------------------------------------------------------------
; Plot: al = 4-bit layer mask (layer 0 in bit 3), mapped through the palette.

blit:
  mov bx, palette
  xlat
  stosb

  test di, di
  jnz top               ; until di wraps around: end of frame

; ---------------------------------------------------------------------------
; End of frame.

  mov dx, 0x3da
.vsync:
  in al, dx
  test al, 8
  jz .vsync             ; wait for the vertical retrace

  dec bp                ; advance time

%ifdef MUSIC
  ; One beat every 8 frames.
  test bp, 7
  jnz .no_beat

  mov si, music

  ; Pattern 1: on a set bit drum 1 plays at a volume that grows every beat;
  ; on a clear bit drum 1 is silent and the synth note toggles on/off.
  rol byte [si+11], 1
  salc                  ; al = 0xff if the bit was set, 0 if not
  jc .vol1
  xor byte [si+4], 0x7f ; synth velocity 127 <-> 0
.vol1:
  and al, 0             ; immediate = drum 1 volume, incremented below
  mov [si+7], al

  ; Pattern 2: drum 2 at volume 90 on a set bit, silent otherwise.
  rol byte [si+12], 1
  salc
  and al, 90
  mov [si+10], al

  ; Alternate both drums between two neighbouring sounds.
  xor byte [si+6], 1
  xor byte [si+9], 1

  ; Later on the synth moves up to note 57. 0xfd8f, not 0xfd90: on beat
  ; 0xfd90 itself the old note is still sent.
  cmp bp, 0xfd8f
  jg .send
  mov byte [si+3], 57
.send:
  mov dl, 0x30          ; dx = 0x330 (dh is still 3 from 0x3da)
  mov cl, 11            ; ch = 0 after the last row copy
  rep outsb             ; MIDI data
  inc dx
  outsb                 ; pattern 2 goes to the command port too

  inc byte [byte si+.vol1+1-music-12] ; si = music+12 now: drum 1 gets louder
.no_beat:

%endif

  ; The intro ends after a fixed number of frames.
  cmp bp, 0xf9b0
  jg near restart
  ret                   ; back to DOS (still in mode 13h)

; ---------------------------------------------------------------------------
; Colour of each combination of layers. The index has layer 0 in bit 3 and
; layer 3 in bit 0.

palette:
  db 0, 108, 4, 38, 124, 79, 27, 84
  db 3, 56, 52, 60, 52, 76, 100, 15

; "FP" font, one 6-byte row per band. Bit k of each byte is pixel column k.
fptext:
  db 0x2e, 0x6e, 0x0a, 0xee, 0xee, 0x0a
  db 0x26, 0xee, 0x0e, 0xee, 0x46, 0x0e
  db 0xe2, 0xca, 0x0a, 0xa2, 0x4a, 0x04

%ifdef MUSIC
; Sent as-is every beat; the code above patches velocities and notes.
music:
  db 0xc0, 53           ; channel 1 program: Voice Oohs
  db 0x90, 55, 127      ; channel 1 note on (synth), velocity gated
  db 0x99, 40, 110      ; channel 10 note on: drum 1 (40/41), velocity patched
  db 0x99, 62, 80       ; channel 10 note on: drum 2 (62/63), velocity patched
  db 0b10011000         ; pattern 1, rotated one bit per beat
  db 0b01101100         ; pattern 2
%endif
