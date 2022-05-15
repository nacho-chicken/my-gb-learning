.PHONY: all clean

.SUFFIXES: .asm .o .gb
.SUFFIXES: .png .2bpp

gfx_src := ../INCLUDES/gfx

ROM := save.gbc
OBJS := main.o
GFX := smile.2bpp egg.2bpp

all: $(GFX) $(ROM)

$(GFX): %.2bpp: $(gfx_src)/%.png
	rgbgfx -o $@ $<

# Running rgbasm with the -h flag because I want to handle the HALT bug myself
$(OBJS): %.o: %.asm
	rgbasm -Lh -o $@ $<

$(ROM): $(OBJS)
	rgblink -n $(ROM:.gbc=.sym) -m $(ROM:.gbc=.map) -o $@ $^
	rgbfix -jvc -k 00 -l 0x33 -m MBC5+RAM+BATTERY -p 0xFF -r 2 -t HELLOWORLD $@

clean:
	rm -f $(ROM) $(OBJS) $(GFX) $(ROM:.gbc=.sym) $(ROM:.gbc=.map)
