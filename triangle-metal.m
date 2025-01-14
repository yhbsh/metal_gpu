#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>
#import <simd/simd.h>

@interface MetalView : NSView
@end

@implementation MetalView

CAMetalLayer              *_metalLayer;
id<MTLDevice>              _device;
id<MTLCommandQueue>        _commandQueue;
id<MTLRenderPipelineState> _pipelineState;
id<MTLBuffer>              _vertexBuffer;
id<MTLBuffer>              _timeBuffer;
NSTimer                   *_timer;
CFTimeInterval             _time;

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }

    _time = CACurrentMediaTime();

    _device                 = MTLCreateSystemDefaultDevice();
    _metalLayer             = [CAMetalLayer layer];
    _metalLayer.device      = _device;
    _metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    self.layer              = _metalLayer;
    _commandQueue           = [_device newCommandQueue];

    id<MTLLibrary>  library      = [_device newLibraryWithURL:[[NSURL alloc] initWithString:@"shaders.metallib"] error:nil];
    id<MTLFunction> vertFunction = [library newFunctionWithName:@"vert_main"];
    id<MTLFunction> fragFunction = [library newFunctionWithName:@"frag_main"];

    MTLRenderPipelineDescriptor *pipelineDescriptor    = [[MTLRenderPipelineDescriptor alloc] init];
    pipelineDescriptor.label                           = @"Pipeline Descriptor";
    pipelineDescriptor.vertexFunction                  = vertFunction;
    pipelineDescriptor.fragmentFunction                = fragFunction;
    pipelineDescriptor.colorAttachments[0].pixelFormat = _metalLayer.pixelFormat;
    pipelineDescriptor.rasterSampleCount               = 4;

    _pipelineState                  = [_device newRenderPipelineStateWithDescriptor:pipelineDescriptor error:nil];
    static const float vertexData[] = {-0.3f, -0.3f, +1.0f, +0.0f, +0.0f, +0.3f, -0.3f, +0.0f, +1.0f, +0.0f, +0.0f, +0.3f, +0.0f, +0.0f, +1.0f};
    _vertexBuffer                   = [_device newBufferWithBytes:vertexData length:sizeof(vertexData) options:MTLResourceStorageModeShared];
    _timer                          = [NSTimer scheduledTimerWithTimeInterval:1.0 / 144.0 target:self selector:@selector(render) userInfo:nil repeats:YES];
    return self;
}

- (void)render {
    CFTimeInterval currentTime = CACurrentMediaTime();
    float          elapsedTime = currentTime - _time;

    id<CAMetalDrawable>  drawable      = [_metalLayer nextDrawable];
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    MTLTextureDescriptor *msaaTextureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:_metalLayer.pixelFormat
                                                                                                     width:drawable.texture.width
                                                                                                    height:drawable.texture.height
                                                                                                 mipmapped:NO];
    msaaTextureDescriptor.textureType           = MTLTextureType2DMultisample;
    msaaTextureDescriptor.sampleCount           = 4;
    msaaTextureDescriptor.usage                 = MTLTextureUsageRenderTarget | MTLTextureUsageShaderRead;
    msaaTextureDescriptor.storageMode           = MTLStorageModePrivate;
    id<MTLTexture> msaaTexture                  = [_device newTextureWithDescriptor:msaaTextureDescriptor];

    MTLRenderPassDescriptor *renderPassDescriptor           = [MTLRenderPassDescriptor renderPassDescriptor];
    renderPassDescriptor.colorAttachments[0].texture        = msaaTexture;
    renderPassDescriptor.colorAttachments[0].resolveTexture = drawable.texture;
    renderPassDescriptor.colorAttachments[0].loadAction     = MTLLoadActionClear;
    renderPassDescriptor.colorAttachments[0].clearColor     = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    renderPassDescriptor.colorAttachments[0].storeAction    = MTLStoreActionMultisampleResolve;

    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setRenderPipelineState:_pipelineState];
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];

    _timeBuffer = [_device newBufferWithBytes:&elapsedTime length:sizeof(elapsedTime) options:MTLResourceStorageModeShared];
    [renderEncoder setVertexBuffer:_timeBuffer offset:0 atIndex:1];

    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [renderEncoder endEncoding];

    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];

        NSMenu     *menu = [[NSMenu alloc] init];
        NSMenuItem *item = [[NSMenuItem alloc] init];
        [menu addItem:item];
        [NSApp setMainMenu:menu];

        NSMenu     *appMenu      = [[NSMenu alloc] init];
        NSString   *quitTitle    = [NSString stringWithFormat:@"Quit %@", [[NSProcessInfo processInfo] processName]];
        NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle action:@selector(terminate:) keyEquivalent:@"q"];
        [appMenu addItem:quitMenuItem];
        [item setSubmenu:appMenu];

        NSWindow  *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 600) styleMask:NSWindowStyleMaskClosable | NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
        MetalView *view   = [[MetalView alloc] initWithFrame:window.contentView.bounds];
        [window setContentView:view];
        [window makeKeyAndOrderFront:nil];
        [window center];

        [NSApp activateIgnoringOtherApps:YES];
        [NSApp run];
    }
    return 0;
}
