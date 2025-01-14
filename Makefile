all: triangle.app/Contents/triangle main.app/Contents/main

main.app/Contents/main: main.m main.metal
	@mkdir -p main.app/Contents
	xcrun metal -c main.metal -o main.air
	xcrun metallib main.air -o main.app/Contents/default.metallib
	clang main.m -o main.app/Contents/main -framework Foundation -framework Cocoa -framework Metal -framework Quartz

triangle.app/Contents/triangle: triangle.m triangle.metal
	@mkdir -p triangle.app/Contents
	xcrun metal -c triangle.metal -o triangle.air
	xcrun metallib triangle.air -o triangle.app/Contents/default.metallib
	clang triangle.m -o triangle.app/Contents/triangle -framework Foundation -framework Cocoa -framework Metal -framework Quartz
