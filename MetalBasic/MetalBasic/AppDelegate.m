//
//  AppDelegate.m
//  MetalBasic
//
//  Created by Zenny Chen on 2018/2/22.
//  Copyright © 2018年 GreenGames Studio. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()<NSWindowDelegate>

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    NSApplication.sharedApplication.windows[0].delegate = self;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (void)windowWillClose:(NSNotification *)notification
{
    [NSApplication.sharedApplication terminate:self];
}

@end

