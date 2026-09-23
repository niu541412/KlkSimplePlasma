#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>
#import <SpriteKit/SpriteKit.h>

@interface KlkSimplePlasmaView : ScreenSaverView
@property(nonatomic, strong) SKView *spriteView;
@property(nonatomic, strong) SKScene *scene;
@property(nonatomic, strong) SKSpriteNode *plasmaNode;
@property(nonatomic, strong) SKUniform *aspectUniform;
- (void)updateSceneLayout;
@end

@implementation KlkSimplePlasmaView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview
{
    self = [super initWithFrame:frame isPreview:isPreview];
    if (!self) {
        return nil;
    }

    self.animationTimeInterval = 1.0 / 60.0;

    _spriteView = [[SKView alloc] initWithFrame:self.bounds];
    _spriteView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _spriteView.preferredFramesPerSecond = 60;
    _spriteView.asynchronous = YES;
    _spriteView.allowsTransparency = NO;
    _spriteView.disableDepthStencilBuffer = YES;
    _spriteView.paused = YES;
    [self addSubview:_spriteView];

    _scene = [SKScene sceneWithSize:self.bounds.size];
    _scene.scaleMode = SKSceneScaleModeResizeFill;
    _scene.backgroundColor = NSColor.blackColor;

    _plasmaNode = [SKSpriteNode spriteNodeWithColor:NSColor.whiteColor size:self.bounds.size];
    _plasmaNode.anchorPoint = CGPointMake(0.5, 0.5);
    _plasmaNode.blendMode = SKBlendModeReplace;
    [_scene addChild:_plasmaNode];

    NSBundle *bundle = [NSBundle bundleForClass:self.class];
    NSURL *shaderURL = [bundle URLForResource:@"Plasma" withExtension:@"fsh"];
    NSError *error = nil;
    NSString *source = shaderURL ? [NSString stringWithContentsOfURL:shaderURL
                                                            encoding:NSUTF8StringEncoding
                                                               error:&error] : nil;
    if (!source) {
        NSLog(@"Klk's Simple Plasma: could not load SpriteKit shader: %@", error);
    } else {
        _aspectUniform = [SKUniform uniformWithName:@"u_aspect" float:1.0f];
        _plasmaNode.shader = [SKShader shaderWithSource:source
                                               uniforms:@[_aspectUniform]];
    }

    [_spriteView presentScene:_scene];
    [self updateSceneLayout];
    return self;
}

- (void)updateSceneLayout
{
    CGSize size = self.bounds.size;
    if (size.width <= 0.0 || size.height <= 0.0) {
        return;
    }

    self.scene.size = size;
    self.plasmaNode.size = size;
    self.plasmaNode.position = CGPointMake(size.width * 0.5, size.height * 0.5);
    self.aspectUniform.floatValue = (float)(size.height / size.width);
}

- (void)layout
{
    [super layout];
    [self updateSceneLayout];
}

- (void)startAnimation
{
    self.spriteView.paused = NO;
    [super startAnimation];
}

- (void)stopAnimation
{
    self.spriteView.paused = YES;
    [super stopAnimation];
}

- (BOOL)isOpaque
{
    return YES;
}

- (BOOL)hasConfigureSheet
{
    return NO;
}

@end
