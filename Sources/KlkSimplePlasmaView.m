#import <Cocoa/Cocoa.h>
#import <MetalKit/MetalKit.h>
#import <QuartzCore/QuartzCore.h>
#import <ScreenSaver/ScreenSaver.h>

typedef struct {
    vector_float2 resolution;
    float time;
    float padding;
} PlasmaUniforms;

@interface KlkSimplePlasmaView : ScreenSaverView <MTKViewDelegate>
@property(nonatomic, strong) MTKView *metalView;
@property(nonatomic, strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic, strong) id<MTLRenderPipelineState> pipelineState;
@property(nonatomic) CFTimeInterval startTime;
@end

@implementation KlkSimplePlasmaView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (!self) {
        return nil;
    }

    self.animationTimeInterval = 1.0 / 60.0;
    _startTime = CACurrentMediaTime();

    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    if (!device) {
        NSLog(@"Klk's Simple Plasma: Metal is unavailable.");
        return self;
    }

    _metalView = [[MTKView alloc] initWithFrame:self.bounds device:device];
    _metalView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _metalView.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    _metalView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    _metalView.framebufferOnly = YES;
    _metalView.paused = YES;
    _metalView.enableSetNeedsDisplay = NO;
    _metalView.delegate = self;
    [self addSubview:_metalView];

    _commandQueue = [device newCommandQueue];

    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSURL *libraryURL = [bundle URLForResource:@"Plasma" withExtension:@"metallib"];
    NSError *error = nil;
    id<MTLLibrary> library = libraryURL ? [device newLibraryWithURL:libraryURL error:&error] : nil;
    if (!library) {
        NSLog(@"Klk's Simple Plasma: could not load Metal library: %@", error);
        return self;
    }

    MTLRenderPipelineDescriptor *descriptor = [MTLRenderPipelineDescriptor new];
    descriptor.label = @"Simple Plasma Pipeline";
    descriptor.vertexFunction = [library newFunctionWithName:@"plasmaVertex"];
    descriptor.fragmentFunction = [library newFunctionWithName:@"plasmaFragment"];
    descriptor.colorAttachments[0].pixelFormat = _metalView.colorPixelFormat;

    _pipelineState = [device newRenderPipelineStateWithDescriptor:descriptor error:&error];
    if (!_pipelineState) {
        NSLog(@"Klk's Simple Plasma: could not create render pipeline: %@", error);
    }

    return self;
}

- (void)startAnimation
{
    self.startTime = CACurrentMediaTime();
    [super startAnimation];
}

- (void)animateOneFrame
{
    [self.metalView draw];
}

- (void)drawRect:(NSRect)rect
{
    [super drawRect:rect];
    [self.metalView draw];
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size
{
}

- (void)drawInMTKView:(MTKView *)view
{
    if (!self.pipelineState || !self.commandQueue || view.drawableSize.width < 1.0 || view.drawableSize.height < 1.0) {
        return;
    }

    MTLRenderPassDescriptor *pass = view.currentRenderPassDescriptor;
    id<CAMetalDrawable> drawable = view.currentDrawable;
    if (!pass || !drawable) {
        return;
    }

    PlasmaUniforms uniforms = {
        .resolution = {(float)view.drawableSize.width, (float)view.drawableSize.height},
        .time = (float)(CACurrentMediaTime() - self.startTime),
        .padding = 0.0f,
    };

    id<MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    commandBuffer.label = @"Simple Plasma Frame";
    id<MTLRenderCommandEncoder> encoder = [commandBuffer renderCommandEncoderWithDescriptor:pass];
    [encoder setRenderPipelineState:self.pipelineState];
    [encoder setFragmentBytes:&uniforms length:sizeof(uniforms) atIndex:0];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    [encoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end
