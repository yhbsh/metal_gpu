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
id<MTLBuffer>                _timeBuffer;
id<MTLLibrary>               _library;
id<MTLFunction>              _vertFunction;
id<MTLFunction>              _fragFunction;
id<CAMetalDrawable>          _drawable;
id<MTLCommandBuffer>         _commandBuffer;
id<MTLRenderCommandEncoder>  _renderEncoder;
CAMetalLayer                *_layer;
NSTimer                     *_timer;
MTLRenderPipelineDescriptor *_renderPipelineDescriptor;
MTLRenderPassDescriptor     *_renderPassDescriptor;
CFTimeInterval               _time;

static const simd_float2 positions[] = {
    {-0.5, -0.5},
    {+0.5, -0.5},
    {+0.0, +0.5},
};
static const simd_float3 colors[] = {
    {1.0, 0.0, 0.0},
    {0.0, 1.0, 0.0},
    {0.0, 0.0, 1.0},
};

- (instancetype)initWithFrame:(CGRect)frame {
    self  = [super initWithFrame:frame];
    _time = CACurrentMediaTime();

    _gpu          = MTLCreateSystemDefaultDevice();
    _layer        = [CAMetalLayer layer];
    _layer.device = _gpu;
    _commandQueue = [_gpu newCommandQueue];
    self.layer    = _layer;

    _library      = [_gpu newLibraryWithURL:[[NSURL alloc] initWithString:@"shaders.metallib"] error:nil];
    _vertFunction = [_library newFunctionWithName:@"vertex_main"];
    _fragFunction = [_library newFunctionWithName:@"fragment_main"];

    _renderPipelineDescriptor                                 = [[MTLRenderPipelineDescriptor alloc] init];
    _renderPipelineDescriptor.label                           = @"Pipeline Descriptor";
    _renderPipelineDescriptor.vertexFunction                  = _vertFunction;
    _renderPipelineDescriptor.fragmentFunction                = _fragFunction;
    _renderPipelineDescriptor.colorAttachments[0].pixelFormat = _layer.pixelFormat;

    _pipelineState = [_gpu newRenderPipelineStateWithDescriptor:_renderPipelineDescriptor error:nil];

    _positionsBuffer = [_gpu newBufferWithBytes:positions length:sizeof(positions) options:MTLResourceStorageModeShared];
    _colorsBuffer    = [_gpu newBufferWithBytes:colors length:sizeof(colors) options:MTLResourceStorageModeShared];

    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 144.0 target:self selector:@selector(render) userInfo:nil repeats:YES];
    return self;
}

- (void)render {
    float elapsed = CACurrentMediaTime() - _time;
    _timeBuffer   = [_gpu newBufferWithBytes:&elapsed length:sizeof(elapsed) options:MTLResourceStorageModeShared];

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
    [_renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
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
