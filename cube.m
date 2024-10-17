#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 600)
                                                       styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        [window setTitle:@"Cube"];
        [window makeKeyAndOrderFront:nil];
        [window center];
        [app activateIgnoringOtherApps:YES];

        id<MTLDevice> device  = MTLCreateSystemDefaultDevice();
        CAMetalLayer *layer   = [CAMetalLayer layer];
        layer.device          = device;
        layer.pixelFormat     = MTLPixelFormatBGRA8Unorm;
        layer.framebufferOnly = YES;

        [window.contentView setLayer:layer];
        [window.contentView setWantsLayer:YES];

        NSMenu *menu     = [[NSMenu alloc] init];
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [menu addItem:item];
        [app setMainMenu:menu];

        NSMenu *appMenu      = [[NSMenu alloc] init];
        NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
        [appMenu addItem:quitItem];
        [item setSubmenu:appMenu];

        static const uint16 indices[]        = {0, 1, 2, 2, 1, 3, 4, 5, 6, 6, 5, 7};
        static const simd_float4 positions[] = {{-0.5, -0.5, +0.0, +1.0}, {+0.5, -0.5, +0.0, +1.0}, {-0.5, +0.5, +0.0, +1.0}, {+0.5, +0.5, +0.0, +1.0},
                                                {+0.0, -0.5, -0.5, +1.0}, {+0.0, +0.5, -0.5, +1.0}, {+0.0, -0.5, +0.5, +1.0}, {+0.0, +0.5, +0.5, +1.0}};
        static const simd_float4 colors[]    = {{+0.0, +0.5, +0.6, +1.0}, {+1.0, +0.5, +0.6, +1.0}};

        id<MTLCommandQueue> commandQueue = [device newCommandQueue];
        id<MTLLibrary> library           = [device newLibraryWithURL:[[NSURL alloc] initWithString:@"shaders.metallib"] error:nil];
        id<MTLFunction> vertFunction     = [library newFunctionWithName:@"vertex_cube_main"];
        id<MTLFunction> fragFunction     = [library newFunctionWithName:@"fragment_cube_main"];

        MTLRenderPipelineDescriptor *renderPipelineDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
        renderPipelineDescriptor.label                           = @"Pipeline Descriptor";
        renderPipelineDescriptor.vertexFunction                  = vertFunction;
        renderPipelineDescriptor.fragmentFunction                = fragFunction;
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = layer.pixelFormat;

        id<MTLRenderPipelineState> pipelineState = [device newRenderPipelineStateWithDescriptor:renderPipelineDescriptor error:nil];

        id<MTLBuffer> positionsBuff = [device newBufferWithBytes:positions length:sizeof(positions) options:MTLResourceStorageModeShared];
        id<MTLBuffer> colorsBuff    = [device newBufferWithBytes:colors length:sizeof(colors) options:MTLResourceStorageModeShared];
        id<MTLBuffer> indicesBuff   = [device newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];

        while (true) {
            @autoreleasepool {

                id<CAMetalDrawable> drawable = [layer nextDrawable];
                if (!drawable) continue;

                simd_float1 elapsed                = CACurrentMediaTime();
                id<MTLBuffer> angleBuff            = [device newBufferWithBytes:&elapsed length:sizeof(elapsed) options:MTLResourceStorageModeShared];
                id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

                MTLRenderPassDescriptor *renderPassDescriptor       = [MTLRenderPassDescriptor renderPassDescriptor];
                renderPassDescriptor.colorAttachments[0].texture    = drawable.texture;
                renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
                renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

                id<MTLRenderCommandEncoder> renderCommandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

                [renderCommandEncoder setRenderPipelineState:pipelineState];
                [renderCommandEncoder setVertexBuffer:positionsBuff offset:0 atIndex:0];
                [renderCommandEncoder setVertexBuffer:colorsBuff offset:0 atIndex:1];
                [renderCommandEncoder setVertexBuffer:angleBuff offset:0 atIndex:2];

                [renderCommandEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                                                 indexCount:sizeof(indices) / sizeof(indices[0])
                                                  indexType:MTLIndexTypeUInt16
                                                indexBuffer:indicesBuff
                                          indexBufferOffset:0];
                [renderCommandEncoder endEncoding];

                [commandBuffer presentDrawable:drawable];
                [commandBuffer commit];

                NSEvent *event;
                while ((event = [app nextEventMatchingMask:NSEventMaskAny untilDate:nil inMode:NSDefaultRunLoopMode dequeue:YES])) {
                    [app sendEvent:event];
                    [app updateWindows];
                }
            }
        }
    }
    return 0;
}
