all: run_cube

run_cube: cube
	./cube

run_triangle: triangle
	./triangle

triangle: shaders.metallib triangle.m
	clang triangle.m -o triangle -framework AppKit -framework Metal -framework QuartzCore

cube: shaders.metallib cube.m
	clang cube.m -o cube -framework AppKit -framework Metal -framework QuartzCore

shaders.metallib: shaders.air
	xcrun metallib shaders.air -o shaders.metallib

shaders.air: shaders.metal
	xcrun metal -c shaders.metal -o shaders.air

clean:
	rm triangle cube
