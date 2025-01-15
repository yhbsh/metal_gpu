all: video.app/Contents/video texture.app/Contents/texture rect.app/Contents/rect triangle.app/Contents/triangle main.app/Contents/main

video.app/Contents/video: video.m video.metal
	@mkdir -p video.app/Contents
	xcrun metal -c video.metal -o video.air
	xcrun metallib video.air -o video.app/Contents/default.metallib
	clang video.m -o video.app/Contents/video -framework Foundation -framework Cocoa -framework Metal -framework Quartz -framework MetalKit $(shell pkg-config --cflags --libs libavformat libavcodec libswscale)

texture.app/Contents/texture: texture.m texture.metal
	@mkdir -p texture.app/Contents
	xcrun metal -c texture.metal -o texture.air
	xcrun metallib texture.air -o texture.app/Contents/default.metallib
	clang texture.m -o texture.app/Contents/texture -framework Foundation -framework Cocoa -framework Metal -framework Quartz -framework MetalKit

rect.app/Contents/rect: rect.m rect.metal
	@mkdir -p rect.app/Contents
	xcrun metal -c rect.metal -o rect.air
	xcrun metallib rect.air -o rect.app/Contents/default.metallib
	clang rect.m -o rect.app/Contents/rect -framework Foundation -framework Cocoa -framework Metal -framework Quartz

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
