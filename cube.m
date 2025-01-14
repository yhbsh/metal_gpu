#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/QuartzCore.h>
#import <simd/simd.h>

@interface MetalView : NSView
@end

@implementation MetalView

id<MTLDevice>                _gpu;
id<MTLCommandQueue>          _commandQueue;
id<MTLRenderPipelineState>   _pipelineState;
id<MTLBuffer>                _positionsBuffer;
id<MTLBuffer>                _colorsBuffer;
id<MTLBuffer>                _indicesBuffer;
id<MTLBuffer>                _timeBuffer;
id<MTLLibrary>               _library;
id<MTLFunction>              _vertFunction;
id<MTLFunction>              _fragFunction;
id<CAMetalDrawable>          _drawable;
id<MTLCommandBuffer>         _commandBuffer;
id<MTLRenderCommandEncoder>  _renderEncoder;
CAMetalLayer                *_layer;
NSTimer                     *_timer;
CFTimeInterval               _time;
MTLRenderPipelineDescriptor *_renderPipelineDescriptor;
MTLRenderPassDescriptor     *_renderPassDescriptor;

static const uint16      indices[]   = {0, 1, 2, 1, 2, 3};
static const simd_float4 positions[] = {
    {-0.5, -0.5, 0.0, 1.0},
    {+0.5, -0.5, 0.0, 1.0},
    {-0.5, +0.5, 0.0, 1.0},
    {+0.5, +0.5, 0.0, 1.0},
};
static const simd_float4 colors[] = {
    {1.0, 0.0, 0.0, 1.0},
    {0.0, 1.0, 0.0, 1.0},
    {0.0, 0.0, 1.0, 1.0},
    {1.0, 1.0, 0.0, 1.0},
};

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    _time         = CACurrentMediaTime();
    _gpu          = MTLCreateSystemDefaultDevice();
    _layer        = [CAMetalLayer layer];
    _layer.device = _gpu;
    _commandQueue = [_gpu newCommandQueue];
    self.layer    = _layer;

    _library      = [_gpu newLibraryWithURL:[[NSURL alloc] initWithString:@"shaders.metallib"] error:nil];
    _vertFunction = [_library newFunctionWithName:@"vertex_cube_main"];
    _fragFunction = [_library newFunctionWithName:@"fragment_cube_main"];

    _renderPipelineDescriptor                                 = [[MTLRenderPipelineDescriptor alloc] init];
    _renderPipelineDescriptor.label                           = @"Pipeline Descriptor";
    _renderPipelineDescriptor.vertexFunction                  = _vertFunction;
    _renderPipelineDescriptor.fragmentFunction                = _fragFunction;
    _renderPipelineDescriptor.colorAttachments[0].pixelFormat = _layer.pixelFormat;

    _pipelineState = [_gpu newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor error:nil];

    _positionsBuffer = [_gpu newBufferWithBytes:positions length:sizeof(positions) options:MTLResourceStorageModeShared];
    _colorsBuffer    = [_gpu newBufferWithBytes:colors length:sizeof(colors) options:MTLResourceStorageModeShared];
    _indicesBuffer   = [_gpu newBufferWithBytes:indices length:sizeof(indices) options:MTLResourceStorageModeShared];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 144.0 target:self selector:@selector(render) userInfo:nil repeats:YES];
    return self;
}

- (void)render {
    simd_float1 elapsed = CACurrentMediaTime() - _time;
    _timeBuffer         = [_gpu newBufferWithBytes:&elapsed length:sizeof(elapsed) options:MTLResourceStorageModeShared];

    _drawable      = [_layer nextDrawable];
    _commandBuffer = [_commandQueue commandBuffer];

    _renderPassDescriptor                                = [MTLRenderPassDescriptor renderPassDescriptor];
    _renderPassDescriptor.colorAttachments[0].texture    = _drawable.texture;
    _renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
    _renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);

    _renderEncoder = [_commandBuffer renderCommandEncoderWithDescriptor:_renderPassDescriptor];
    [_renderEncoder setRenderPipelineState:_pipelineState];
    [_renderEncoder setVertexBuffer:_positionsBuffer offset:0 atIndex:0];
    [_renderEncoder setVertexBuffer:_colorsBuffer offset:0 atIndex:1];
    [_renderEncoder setVertexBuffer:_timeBuffer offset:0 atIndex:2];
    [_renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle
                               indexCount:sizeof(indices) / sizeof(indices[0])
                                indexType:MTLIndexTypeUInt16
                              indexBuffer:_indicesBuffer
                        indexBufferOffset:0];
    [_renderEncoder endEncoding];

    [_commandBuffer presentDrawable:_drawable];
    [_commandBuffer commit];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];

        NSMenu     *menu = [[NSMenu alloc] init];
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [menu addItem:item];
        [app setMainMenu:menu];

        NSMenu     *appMenu  = [[NSMenu alloc] init];
        NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"Quit" action:@selector(terminate:) keyEquivalent:@"q"];
        [appMenu addItem:quitItem];
        [item setSubmenu:appMenu];

        NSWindow  *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 600)
                                                       styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                         backing:NSBackingStoreBuffered
                                                           defer:NO];
        MetalView *view   = [[MetalView alloc] initWithFrame:window.contentView.bounds];
        [window setContentView:view];
        [window makeKeyAndOrderFront:nil];
        [window center];

        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
