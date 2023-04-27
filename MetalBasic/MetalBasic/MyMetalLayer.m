//
//  MyMetalLayer.m
//  MetalBasic
//
//  Created by Zenny Chen on 2018/2/22.
//  Copyright © 2018年 GreenGames Studio. All rights reserved.
//

#import "MyMetalLayer.h"
#import "ViewController.h"

@import Metal;

@implementation MyMetalLayer
{
@private
    
    // 渲染相关
    
    /// 命令队列
    id<MTLCommandQueue> mCommandQueue;
    
    /// Metal Shader的库
    id<MTLLibrary> mLibrary;
    
    /// 用于通用计算的原始数据缓存
    int *mSrc1Buffer, *mSrc2Buffer;
    
    /// 计算目的缓存
    id<MTLBuffer> mComputeSrc1Buffer;
    id<MTLBuffer> mComputeSrc2Buffer;
    id<MTLBuffer> mComputeDstBuffer;
    id<MTLBuffer> mComputeDeviceBuffer;
}

- (instancetype)init
{
    self = [super init];
    
    self.backgroundColor = NSColor.clearColor.CGColor;
    
    // 指定该layer为实体，以优化绘制
    self.opaque = YES;
    
    // 使用默认的RGBA8888像素格式
    self.pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // 默认为YES，但如果我们要在最后渲染的layer上执行计算，那么我们可以将此参数设置为NO。
    self.framebufferOnly = YES;
    
    return self;
}

- (void)setup
{
    // 1、关联Metal设备
    var devices = MTLCopyAllDevices();
    NSLog(@"There are %tu Metal devices available!", devices.count);
    
    var device = devices[0];
    NSLog(@"The current device name: %@", device.name);
    self.device = device;
    
    [devices release];
    
    // 3、创建命令队列以及库
    mCommandQueue = device.newCommandQueue;
    mLibrary = device.newDefaultLibrary;
}

- (void)doSumup
{
    var commandBuffer = mCommandQueue.commandBuffer;
    
    // 2、创建并设置计算命令编码器
    var computeEncoder = commandBuffer.computeCommandEncoder;
    
    var computeProgram = [mLibrary newFunctionWithName:@"sum_square"];
    if(computeProgram == nil)
    {
        NSLog(@"计算着色器获取失败");
        return;
    }
    
    var pipelineState = [self.device newComputePipelineStateWithFunction:computeProgram error:NULL];
    [computeProgram release];
    
    if(pipelineState == nil)
    {
        NSLog(@"计算流水线创建失败");
        return;
    }
    
    NSLog(@"max threadgroup size: %tu", pipelineState.maxTotalThreadsPerThreadgroup);
    NSLog(@"thread execution width: %tu", pipelineState.threadExecutionWidth);
    
    // 分配线程组大小以及线程组个数
    const var groupSize = pipelineState.maxTotalThreadsPerThreadgroup;
    const MTLSize threadsPerGroup = {groupSize, 1, 1};
    const MTLSize numTreadGroups = {1024 * 1024 / groupSize, 1, 1};
    
    [computeEncoder setComputePipelineState:pipelineState];
    
    [computeEncoder setBuffer:mComputeDeviceBuffer offset:0 atIndex:0];
    
    [commandBuffer addCompletedHandler:^void(id<MTLCommandBuffer> buf){
        int *pDst = mComputeDstBuffer.contents;
        for(int i = 0; i < 1024 * 1024; i++)
        {
            if(pDst[i] != (mSrc1Buffer[i] + mSrc2Buffer[i]) * (mSrc1Buffer[i] + mSrc2Buffer[i]))
            {
                NSLog(@"Not equal @%d", i);
                return;
            }
        }
        
        NSLog(@"Equal completely!");
        
        if(mSrc1Buffer != NULL)
        {
            free(mSrc1Buffer);
            mSrc1Buffer = NULL;
        }
        if(mSrc2Buffer != NULL)
        {
            free(mSrc2Buffer);
            mSrc2Buffer = NULL;
        }
    }];
    
    // 分派计算线程
    [computeEncoder dispatchThreadgroups:numTreadGroups threadsPerThreadgroup:threadsPerGroup];
    [computeEncoder endEncoding];
    
    // 提交
    [commandBuffer commit];
    
    [pipelineState release];
}

- (void)doCompute
{
    if(mComputeDstBuffer != nil)
        return;
    
    // 初始化内部缓存
    const var length = 1024 * 1024 * sizeof(*mSrc1Buffer);
    // Totally 32 buffer addresses
    const int deviceBufferLength = 32 * 2;
    mSrc1Buffer = malloc(length);
    mSrc2Buffer = malloc(length);
    
    for(int i = 0; i < 1024 * 1024; i++)
    {
        mSrc1Buffer[i] = i * 2;
        mSrc2Buffer[i] = i * 2 + 1;
    }
    
    // 1、创建命令缓存
    var commandBuffer = mCommandQueue.commandBuffer;
    
    // 2、创建并设置计算命令编码器
    var computeEncoder = commandBuffer.computeCommandEncoder;
    
    // 创建缓存对象
    var src1Buf = [self.device newBufferWithBytes:mSrc1Buffer length:length options:MTLResourceCPUCacheModeWriteCombined];
    var src2Buf = [self.device newBufferWithBytes:mSrc2Buffer length:length options:MTLResourceCPUCacheModeWriteCombined];
    mComputeDstBuffer = [self.device newBufferWithLength:length options:MTLResourceStorageModeShared];
    mComputeDeviceBuffer = [self.device newBufferWithLength:deviceBufferLength * sizeof(uint) options:MTLResourceStorageModePrivate];
    
    // 创建compute shader程序
    var computeProgram = [mLibrary newFunctionWithName:@"translate_buffers_address"];
    if(computeProgram == nil)
    {
        NSLog(@"计算着色器获取失败");
        return;
    }
    
    var pipelineState = [self.device newComputePipelineStateWithFunction:computeProgram error:NULL];
    [computeProgram release];
    
    if(pipelineState == nil)
    {
        NSLog(@"计算流水线创建失败");
        return;
    }
    
    NSLog(@"max threadgroup size: %tu", pipelineState.maxTotalThreadsPerThreadgroup);
    NSLog(@"thread execution width: %tu", pipelineState.threadExecutionWidth);
    
    // 分配线程组大小以及线程组个数
    const MTLSize threadsPerGroup = {deviceBufferLength, 1, 1};
    const MTLSize numTreadGroups = {1, 1, 1};
    
    [computeEncoder setComputePipelineState:pipelineState];
    
    [computeEncoder setBuffer:src1Buf offset:0 atIndex:0];
    [computeEncoder setBuffer:src2Buf offset:0 atIndex:1];
    [computeEncoder setBuffer:mComputeDstBuffer offset:0 atIndex:2];
    [computeEncoder setBuffer:mComputeDeviceBuffer offset:0 atIndex:3];
    
    [commandBuffer addCompletedHandler:^void(id<MTLCommandBuffer> buf){
        [self doSumup];
    }];
    
    // 分派计算线程
    [computeEncoder dispatchThreadgroups:numTreadGroups threadsPerThreadgroup:threadsPerGroup];
    [computeEncoder endEncoding];
    
    // 提交
    [commandBuffer commit];
    
    // 目前macOS有一个bug，如果将这里的对计算流水线状态的释放提前会导致性能剖析程序的崩溃
    [pipelineState release];
    
    NSLog(@"doCompute returned!");
}

- (void)dealloc
{
    if(mSrc1Buffer != NULL)
    {
        free(mSrc1Buffer);
        mSrc1Buffer = NULL;
    }
    if(mSrc2Buffer != NULL)
    {
        free(mSrc2Buffer);
        mSrc2Buffer = NULL;
    }
    
    [mCommandQueue release];
    
    [mLibrary release];
    
    [mComputeSrc1Buffer release];
    [mComputeSrc2Buffer release];
    [mComputeDstBuffer release];
    [mComputeDeviceBuffer release];
    
    [super dealloc];
}

@end

