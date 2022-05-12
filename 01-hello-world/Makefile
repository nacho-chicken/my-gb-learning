.PHONY: all clean

.SUFFIXES: .asm .o .gb

ROM := hello-world.gb
OBJS := main.o

all: $(ROM)

$(OBJS): %.o: %.asm
	rgbasm -Lh -o $@ $<

$(ROM): $(OBJS)
	rgblink -n $(ROM:.gb=.sym) -m $(ROM:.gb=.map) -o $@ $^
	rgbfix -v -p 0xFF $(ROM)

clean:
	rm -f $(ROM) $(OBJS) $(ROM:.gb=.sym) $(ROM:.gb=.map)
