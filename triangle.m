#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>

int main(int argc, const char *argv[]) {
    NSError *error;
    NSApplication *app = [NSApplication sharedApplication];
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 600)
                                                   styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window makeKeyAndOrderFront:nil];
    [window center];
    [app activateIgnoringOtherApps:YES];

    CAMetalLayer *layer = [CAMetalLayer layer];
    [window.contentView setLayer:layer];
    [window.contentView setWantsLayer:YES];

    // clang-format off
    static const float vertexData[] = {
        // Position          // Color
        +0.0f, +0.5f, +0.0f,  +1.0f, +0.0f, +0.0f,
        -0.5f, -0.5f, +0.0f,  +0.0f, +1.0f, +0.0f,
        +0.5f, -0.5f, +0.0f,  +0.0f, +0.0f, +1.0f,
    };

    // clang-format on

    id<MTLDevice> device  = MTLCreateSystemDefaultDevice();
    layer.device          = device;
    layer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
    layer.framebufferOnly = YES;

    id<MTLLibrary> library = [device newLibraryWithURL:[[NSURL alloc] initWithString:@"shaders.metallib"] error:&error];
    if (!library) {
        NSLog(@"cannot find library");
        return 1;
    }

    id<MTLFunction> vertexFunc = [library newFunctionWithName:@"vertex_main"];
    if (!vertexFunc) {
        NSLog(@"cannot find vertex function");
        return 1;
    }
    id<MTLFunction> fragmentFunc = [library newFunctionWithName:@"fragment_main"];
    if (!fragmentFunc) {
        NSLog(@"cannot find fragment function");
        return 1;
    }

    MTLRenderPipelineDescriptor *renderPipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    if (!renderPipelineDescriptor) {
        NSLog(@"cannot create render pipeline descriptor");
        return 1;
    }

    renderPipelineDescriptor.vertexFunction                  = vertexFunc;
    renderPipelineDescriptor.fragmentFunction                = fragmentFunc;
    renderPipelineDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;

    MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
    if (!vertexDescriptor) {
        NSLog(@"cannot create vertex descriptor");
        return 1;
    }

    vertexDescriptor.attributes[0].format      = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[0].offset      = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;

    vertexDescriptor.attributes[1].format      = MTLVertexFormatFloat3;
    vertexDescriptor.attributes[1].offset      = 3 * sizeof(float);
    vertexDescriptor.attributes[1].bufferIndex = 0;

    vertexDescriptor.layouts[0].stride       = 6 * sizeof(float);
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.layouts[0].stepRate     = 1;

    renderPipelineDescriptor.vertexDescriptor = vertexDescriptor;

    id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:&error];
    if (!pipelineState) {
        NSLog(@"cannot create pipeline state %@", error);
        return 1;
    }

    id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
    if (!vertexBuffer) {
        NSLog(@"cannot create vertex buffer %@", error);
        return 1;
    }

    id<MTLCommandQueue> commandQueue = [device newCommandQueue];
    if (!commandQueue) {
        NSLog(@"cannot create command queue");
        return 1;
    }

    BOOL quit = NO;
    while (!quit) {
        NSEvent *event;
        while ((event = [app nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {
            [app sendEvent:event];
            [app updateWindows];
            if ([event type] == NSEventTypeKeyDown && [event keyCode] == 12) quit = YES;
        }

        id<CAMetalDrawable> drawable = [layer nextDrawable];
        if (!drawable) continue;

        MTLRenderPassDescriptor *renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
        renderPassDescriptor.colorAttachments[0].texture    = drawable.texture;
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

        id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

        id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderCommandEncoder setRenderPipelineState:pipelineState];
        [renderCommandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

        [renderCommandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
        [renderCommandEncoder endEncoding];

        [commandBuffer presentDrawable:drawable];
        [commandBuffer commit];
    }

    return 0;
}
