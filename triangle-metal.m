#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <QuartzCore/CAMetalLayer.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong, nonatomic) NSWindow *window;
@property(strong, nonatomic) id<MTLDevice> metalDevice;
@property(strong, nonatomic) CAMetalLayer *metalLayer;
@property(strong, nonatomic) id<MTLRenderPipelineState> pipelineState;
@property(strong, nonatomic) id<MTLCommandQueue> commandQueue;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 800, 600)
                                            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  [self.window setTitle:@"Metal Basic Example"];
  [self.window makeKeyAndOrderFront:nil];
  [self.window center];

  [self setupMetal];
  [self setupPipeline];

  [self redraw];
  [self setupMenu];
}

- (void)setupMetal {
  self.metalDevice = MTLCreateSystemDefaultDevice();
  self.metalLayer = [CAMetalLayer layer];
  self.metalLayer.device = self.metalDevice;
  self.metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
  self.metalLayer.framebufferOnly = YES;
  self.metalLayer.frame = [self.window.contentView bounds];
  [self.window.contentView setLayer:self.metalLayer];
  [self.window.contentView setWantsLayer:YES];
  self.commandQueue = [self.metalDevice newCommandQueue];
}

- (void)setupPipeline {
  NSError *error = nil;
  NSURL *url = [[NSBundle mainBundle] URLForResource:@"shaders" withExtension:@"metallib"];
  id<MTLLibrary> library = [self.metalDevice newLibraryWithURL:url error:&error];
  if (!library) {
    NSLog(@"Error loading metal library: %@", error);
    return;
  }

  id<MTLFunction> vertexFunction = [library newFunctionWithName:@"vertexShader"];
  id<MTLFunction> fragmentFunction = [library newFunctionWithName:@"fragmentShader"];

  MTLVertexDescriptor *vertexDescriptor = [[MTLVertexDescriptor alloc] init];
  vertexDescriptor.attributes[0].format = MTLVertexFormatFloat3;
  vertexDescriptor.attributes[0].offset = 0;
  vertexDescriptor.attributes[0].bufferIndex = 0;
  vertexDescriptor.layouts[0].stride = sizeof(float) * 3;
  vertexDescriptor.layouts[0].stepRate = 1;
  vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;

  MTLRenderPipelineDescriptor *pipelineDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
  pipelineDescriptor.vertexFunction = vertexFunction;
  pipelineDescriptor.fragmentFunction = fragmentFunction;
  pipelineDescriptor.vertexDescriptor = vertexDescriptor;
  pipelineDescriptor.colorAttachments[0].pixelFormat = self.metalLayer.pixelFormat;

  self.pipelineState = [self.metalDevice newRenderPipelineStateWithDescriptor:pipelineDescriptor error:&error];
  if (!self.pipelineState) {
    NSLog(@"Failed to create pipeline state: %@", error);
  }
}

- (void)redraw {
  id<CAMetalDrawable> drawable = [self.metalLayer nextDrawable];
  if (!drawable) {
    return;
  }

  MTLRenderPassDescriptor *passDescriptor = [MTLRenderPassDescriptor renderPassDescriptor];
  passDescriptor.colorAttachments[0].texture = drawable.texture;
  passDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
  passDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 1);
  passDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;

  id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
  id<MTLRenderCommandEncoder> commandEncoder = [commandBuffer renderCommandEncoderWithDescriptor:passDescriptor];

  float vertexData[] = {
      0.0f, 1.0f, 0.0f, -1.0f, -1.0f, 0.0f, 1.0f, -1.0f, 0.0f,
  };
  NSUInteger vertexDataSize = sizeof(vertexData);
  id<MTLBuffer> vertexBuffer = [self.metalDevice newBufferWithBytes:vertexData length:vertexDataSize options:MTLResourceStorageModeShared];
  [commandEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];

  [commandEncoder setRenderPipelineState:self.pipelineState];
  [commandEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
  [commandEncoder endEncoding];

  [commandBuffer presentDrawable:drawable];
  [commandBuffer commit];
}

- (void)setupMenu {
  NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];
  NSMenuItem *itemApp = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  [mainMenu addItem:itemApp];

  NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Application"];
  NSString *name = [[NSProcessInfo processInfo] processName];
  NSString *title = [NSString stringWithFormat:@"Quit %@", name];
  NSMenuItem *itemQuit = [[NSMenuItem alloc] initWithTitle:title action:@selector(terminate:) keyEquivalent:@"q"];
  [menu addItem:itemQuit];
  [itemApp setSubmenu:menu];

  [NSApp setMainMenu:mainMenu];
}

@end

int main(int argc, char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app run];
  }
  return 0;
}
