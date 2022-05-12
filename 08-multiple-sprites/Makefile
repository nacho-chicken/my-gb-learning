.PHONY: all clean

.SUFFIXES: .asm .o .gb
.SUFFIXES: .png .2bpp

ROM := multisprite.gb
OBJS := main.o
GFX := ../INCLUDES/gfx/smile.2bpp

all: $(GFX) $(ROM)

$(GFX): %.2bpp: %.png
	rgbgfx -o $@ $<

# Running rgbasm with the -h flag because I want to handle the HALT bug myself
$(OBJS): %.o: %.asm
	rgbasm -Lh -o $@ $<

$(ROM): $(OBJS)
	rgblink -n $(ROM:.gb=.sym) -m $(ROM:.gb=.map) -o $@ $^
	rgbfix -v -p 0xFF $(ROM)

clean:
	rm -f $(ROM) $(OBJS) $(GFX) $(ROM:.gb=.sym) $(ROM:.gb=.map)
