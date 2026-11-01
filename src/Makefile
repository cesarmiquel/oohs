OPTIMIZE=-O0  # Optimiter off

all: fp26.com

fp26.com: fp26.asm Makefile
	nasm fp26.asm -fbin -l fp26.lst $(OPTIMIZE) -DMUSIC -o ../fp26.com
	nasm fp26-claude.asm -fbin $(OPTIMIZE) -DMUSIC -o ../fp26c.com
	#nasm fp26.asm -fbin -l fp26.lst $(OPTIMIZE) -o ../fp26.com
	cp ../fp26.com ../DEBUG/
	./showsize.sh
	dosbox -conf ../dosbox.conf ../fp26.com

run:
	dosbox -conf ../dosbox.conf ../fp26.com

clean:
	rm ../fp25.com
