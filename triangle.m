#import <Cocoa/Cocoa.h>

@interface TriangleView : NSView
@end

@implementation TriangleView

- (void)drawRect:(NSRect)dirtyRect {
  [super drawRect:dirtyRect];

  NSBezierPath *path = [NSBezierPath bezierPath];
  [path moveToPoint:NSMakePoint(NSMidX(self.bounds), NSMaxY(self.bounds) * 0.75)];
  [path lineToPoint:NSMakePoint(NSMaxX(self.bounds) * 0.25, NSMaxY(self.bounds) * 0.25)];
  [path lineToPoint:NSMakePoint(NSMaxX(self.bounds) * 0.75, NSMaxY(self.bounds) * 0.25)];
  [path closePath];

  [[NSColor redColor] setFill];
  [path fill];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong, nonatomic) NSWindow *window;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 640, 480)
                                            styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                              backing:NSBackingStoreBuffered
                                                defer:NO];
  [self.window setTitle:@"Hello, Objective-C Window!"];
  [self.window makeKeyAndOrderFront:nil];
  [self.window center];

  TriangleView *view = [[TriangleView alloc] initWithFrame:[self.window.contentView bounds]];
  [self.window setContentView:view];
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

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    NSApplication *app = [NSApplication sharedApplication];
    AppDelegate *delegate = [[AppDelegate alloc] init];
    app.delegate = delegate;
    [app setActivationPolicy:NSApplicationActivationPolicyRegular];
    [app run];
  }
  return 0;
}
