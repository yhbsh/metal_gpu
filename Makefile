FRAMEWORKS := -framework AppKit -framework Metal -framework QuartzCore -framework MetalKit

SRCS := $(wildcard *.m)
PROGS := $(SRCS:.m=)

METAL_SRC := $(wildcard *.metal)
METAL_LIB := $(METAL_SRC:.metal=.metallib)

all: $(METAL_LIB) $(PROGS)

%: %.m
	cc $< -o $@ $(FRAMEWORKS)

%.metallib: %.air
	xcrun metallib $< -o $@

%.air: %.metal
	xcrun metal -c $< -o $@

clean:
	rm -f $(PROGS) *.metallib *.air

.PHONY: all clean
