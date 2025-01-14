triangle-metal: shaders.metallib triangle-metal.m
	clang triangle-metal.m -o triangle-metal -framework AppKit -framework Metal -framework QuartzCore

shaders.metallib: shaders.air
	xcrun metallib shaders.air -o shaders.metallib

shaders.air: shaders.metal
	xcrun metal -c shaders.metal -o shaders.air
