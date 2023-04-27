//
//  MyMetalLayer.h
//  MetalBasic
//
//  Created by Zenny Chen on 2018/2/22.
//  Copyright © 2018年 GreenGames Studio. All rights reserved.
//

@import QuartzCore;
@import Cocoa;

@interface MyMetalLayer : CAMetalLayer

/// 设置当前Metal Layer
- (void)setup;

/// 通过Metal API做通用计算
- (void)doCompute;

@end

