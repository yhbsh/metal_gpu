#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/CAMetalLayer.h>

int main() {
    NSApplication *application = [NSApplication sharedApplication];
    NSRect frame = NSMakeRect(500, 200, 800, 600);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                   styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    CAMetalLayer *metalLayer = [CAMetalLayer layer];
    [window makeKeyAndOrderFront:nil];
    [window.contentView setLayer:metalLayer];
    [window.contentView setWantsLayer:YES];

    id<MTLDevice> gpu = MTLCreateSystemDefaultDevice();
    metalLayer.device = gpu;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.framebufferOnly = YES;
    metalLayer.frame = frame;

    NSString *libraryPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"metallib"];
    id<MTLLibrary> library = [gpu newLibraryWithURL:[NSURL fileURLWithPath:libraryPath] error:nil];
    id<MTLFunction> vertFn = [library newFunctionWithName:@"vert_main"];
    id<MTLFunction> fragFn = [library newFunctionWithName:@"frag_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.vertexFunction = vertFn;
    pipelineDescriptor.fragmentFunction = fragFn;
    pipelineDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;

    id<MTLRenderPipelineState> pipelineState = [gpu newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
    id<MTLCommandQueue> commandQueue = [gpu newCommandQueue];

    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"image" ofType:@"jpg"];
    MTKTextureLoader *textureLoader = [[MTKTextureLoader alloc] initWithDevice:gpu];
    id<MTLTexture> texture = [textureLoader newTextureWithContentsOfURL:[NSURL fileURLWithPath:imagePath] options:nil error:nil];

    BOOL quit = NO;
    while (!quit) {
        NSEvent *event;
        while ((event = [application nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {
            [application sendEvent:event];
            [application updateWindows];
            if ([event type] == NSEventTypeKeyDown) {
                quit = YES;
            }
        }
        
        @autoreleasepool {
            id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
            if (drawable) {
                MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
                passDescriptor.colorAttachments[0].texture = drawable.texture;
                passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
                passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
                passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

                id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];
                id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];
                [encoder setRenderPipelineState:pipelineState];
                [encoder setFragmentTexture:texture atIndex:0];
                [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
                [encoder endEncoding];
                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];
            }
        }
    }
    return 0;
}
