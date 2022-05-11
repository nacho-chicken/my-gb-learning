.PHONY: all clean

.SUFFIXES: .asm .o .gb
.SUFFIXES: .png .2bpp

ROM := sprites.gb
OBJS := main.o
GFX := ../INCLUDES/gfx/smile.2bpp

all: $(GFX) $(ROM)

$(GFX): %.2bpp: %.png
	rgbgfx -o $@ $<

$(OBJS): %.o: %.asm
	rgbasm -Lh -o $@ $<

$(ROM): $(OBJS)
	rgblink -n $(ROM:.gb=.sym) -m $(ROM:.gb=.map) -o $@ $^
	rgbfix -v -p 0xFF $(ROM)

clean:
	rm -f $(ROM) $(OBJS) $(GFX) $(ROM:.gb=.sym) $(ROM:.gb=.map)
