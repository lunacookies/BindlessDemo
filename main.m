@import AppKit;
@import Metal;
@import QuartzCore;
@import simd;

typedef struct {
	simd_float2 position;
	simd_float2 resolution;
} VertexArguments;

@interface MainView : NSView
@end

@implementation MainView {
	CAMetalLayer *metalLayer;
	CADisplayLink *displayLink;

	id<MTLDevice> device;
	id<MTLCommandQueue> commandQueue;
	id<MTLRenderPipelineState> pipelineState;

	simd_float2 mouseLocation;
}

- (instancetype)initWithFrame:(NSRect)frame {
	self = [super initWithFrame:frame];

	self.wantsLayer = YES;
	metalLayer = [CAMetalLayer layer];
	self.layer = metalLayer;

	device = MTLCreateSystemDefaultDevice();
	metalLayer.device = device;
	commandQueue = [device newCommandQueue];

	id<MTLLibrary> library = [device newDefaultLibrary];

	MTLRenderPipelineDescriptor *descriptor = [[MTLRenderPipelineDescriptor alloc] init];
	descriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat;
	descriptor.vertexFunction = [library newFunctionWithName:@"vertex_main"];
	descriptor.fragmentFunction = [library newFunctionWithName:@"fragment_main"];

	pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:nil];

	displayLink = [self displayLinkWithTarget:self selector:@selector(displayLinkDidFire)];
	[displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];

	return self;
}

- (void)displayLinkDidFire {
	id<CAMetalDrawable> drawable = [metalLayer nextDrawable];
	id<MTLCommandBuffer> commandBuffer = [commandQueue commandBuffer];

	MTLRenderPassDescriptor *descriptor = [[MTLRenderPassDescriptor alloc] init];
	descriptor.colorAttachments[0].texture = drawable.texture;
	descriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
	descriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1);

	id<MTLRenderCommandEncoder> encoder =
	        [commandBuffer renderCommandEncoderWithDescriptor:descriptor];

	[encoder setRenderPipelineState:pipelineState];

	VertexArguments arguments = {0};
	arguments.position = mouseLocation;
	arguments.resolution.x = self.frame.size.width;
	arguments.resolution.y = self.frame.size.height;

	[encoder setVertexBytes:&arguments length:sizeof(arguments) atIndex:0];

	[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];

	[encoder endEncoding];

	[commandBuffer presentDrawable:drawable];
	[commandBuffer commit];
}

- (void)mouseMoved:(NSEvent *)event {
	mouseLocation.x = event.locationInWindow.x;
	mouseLocation.y = self.frame.size.height - event.locationInWindow.y;
}

- (void)viewDidChangeBackingProperties {
	[super viewDidChangeBackingProperties];
	[self updateFramebuffer];
}

- (void)setFrameSize:(NSSize)size {
	[super setFrameSize:size];
	[self updateFramebuffer];
}

- (void)updateFramebuffer {
	metalLayer.drawableSize = [self convertSizeToBacking:self.frame.size];
	metalLayer.contentsScale = self.window.backingScaleFactor;
}

- (void)updateTrackingAreas {
	NSTrackingArea *area =
	        [[NSTrackingArea alloc] initWithRect:self.bounds
	                                     options:NSTrackingActiveAlways | NSTrackingMouseMoved
	                                       owner:self
	                                    userInfo:nil];
	[self addTrackingArea:area];
}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate {
	NSWindow *window;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
	NSWindowStyleMask styleMask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
	                              NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
	window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 500, 300)
	                                     styleMask:styleMask
	                                       backing:NSBackingStoreBuffered
	                                         defer:NO];
	window.contentView = [[MainView alloc] init];
	[window makeKeyAndOrderFront:nil];

	[NSApp activate];
}

@end

int main(void) {
	setenv("MTL_HUD_ENABLED", "1", 1);
	setenv("MTL_SHADER_VALIDATION", "1", 1);
	setenv("MTL_DEBUG_LAYER", "1", 1);
	setenv("MTL_DEBUG_LAYER_WARNING_MODE", "nslog", 1);

	[NSApplication sharedApplication];
	AppDelegate *appDelegate = [[AppDelegate alloc] init];
	NSApp.delegate = appDelegate;
	[NSApp run];
}
