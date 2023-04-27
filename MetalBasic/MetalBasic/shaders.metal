//
//  shaders.metal
//  MetalBasic
//
//  Created by Zenny Chen on 2018/2/22.
//  Copyright © 2018年 GreenGames Studio. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void translate_buffers_address(constant int *src1 [[ buffer(0) ]],
                                      constant int *src2 [[ buffer(1) ]],
                                      device int *dst [[ buffer(2) ]],
                                      device uint* deviceBuffersBuf [[ buffer(3) ]],
                                      uint localID [[ thread_position_in_threadgroup ]])
{
    // Initialize the buffer. Just clear it to zero.
    deviceBuffersBuf[localID] = 0;
    threadgroup_barrier(mem_flags::mem_threadgroup);
    
    if(localID == 0)
    {
        constexpr auto highShift = (sizeof(uintptr_t) * 8 / 2);
        constexpr auto lowMask = 0xffff'ffffU >> ((sizeof(uintptr_t) * 8 / 2) & 0x1f);
        deviceBuffersBuf[0] = uintptr_t(src1) >> highShift;
        deviceBuffersBuf[1] = uintptr_t(src1) & lowMask;
        deviceBuffersBuf[2] = uintptr_t(src2) >> highShift;
        deviceBuffersBuf[3] = uintptr_t(src2) & lowMask;
        deviceBuffersBuf[4] = uintptr_t(dst) >> highShift;
        deviceBuffersBuf[5] = uintptr_t(dst) & lowMask;
    }
}

// compute shader function
kernel void sum_square(device uint *deviceBuffersBuf [[ buffer(0) ]],
                       uint gid [[ thread_position_in_grid ]],
                       uint nSIMDGroups [[threads_per_grid]]
                       )
{
    constexpr auto highShift = (sizeof(uintptr_t) * 8 / 2);
    
    auto const src1High = (uintptr_t)deviceBuffersBuf[0] << highShift;
    constant int *src1 = (constant int*)((uintptr_t)deviceBuffersBuf[1] | src1High);
    
    auto const src2High = (uintptr_t)deviceBuffersBuf[2] << highShift;
    constant int *src2 = (constant int*)((uintptr_t)deviceBuffersBuf[3] | src2High);
    
    auto const dstHigh = (uintptr_t)deviceBuffersBuf[4] << highShift;
    device int *dst = (device int*)((uintptr_t)deviceBuffersBuf[5] | dstHigh);
    
    auto val1 = src1[gid];
    auto val2 = src2[gid];
    auto sum = val1 + val2;
    
    auto a = _Generic(sum, int: 0, float: 1, default: -1);
    
    dst[gid] = sum * sum + a;
}

