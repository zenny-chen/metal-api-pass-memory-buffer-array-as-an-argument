//
//  ViewController.m
//  MetalBasic
//
//  Created by Zenny Chen on 2018/2/22.
//  Copyright © 2018年 GreenGames Studio. All rights reserved.
//

#import "ViewController.h"
#import "MyMetalLayer.h"

@implementation ViewController
{
@private
    
    MyMetalLayer *mMetalLayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
    self.view.wantsLayer = YES;
    
    const var viewSize = self.view.frame.size;
    
    var initY = viewSize.height - 30.0 - 35.0;
    
    var *button = [NSButton.alloc initWithFrame:NSMakeRect(20.0f, initY, 70.0f, 35.0f)];
    button.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    [button setButtonType:NSMomentaryPushInButton];
    button.bezelStyle = NSRoundedBezelStyle;
    button.title = @"Show";
    [button setTarget:self];
    [button setAction:@selector(showButtonClicked:)];
    [self.view addSubview:button];
    [button release];
    
    initY -= 50.0;
    
    button = [NSButton.alloc initWithFrame:NSMakeRect(20.0f, initY, 70.0f, 35.0f)];
    button.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    [button setButtonType:NSMomentaryPushInButton];
    button.bezelStyle = NSRoundedBezelStyle;
    button.title = @"Close";
    [button setTarget:self];
    [button setAction:@selector(closeButtonClicked:)];
    [self.view addSubview:button];
    [button release];
}

- (void)showButtonClicked:(id)sender
{
    if(mMetalLayer != nil)
        return;
    
    const CGSize viewSize = self.view.frame.size;
    
    const CGFloat x = (viewSize.width - 448.0) * 0.5;
    const CGFloat deltaY = (viewSize.height - 448.0) * 0.5;
    
    mMetalLayer = MyMetalLayer.new;
    mMetalLayer.contentsScale = NSScreen.mainScreen.backingScaleFactor;
    
    // 将metal layer设置为一个正方形
    mMetalLayer.frame = CGRectMake(x, viewSize.height - deltaY - 448.0, 448.0, 448.0);
    
    // setup方法必须在设置frame之后，add到父layer之前调用
    [mMetalLayer setup];
    
    [mMetalLayer doCompute];
    
    [mMetalLayer release];
    mMetalLayer = nil;
}

- (void)closeButtonClicked:(id)sender
{
    if(mMetalLayer == nil)
        return;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

@end

