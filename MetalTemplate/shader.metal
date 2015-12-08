//
//  shader.metal
//  MetalTemplate
//
//  Created by SuguruSasaki on 2015/12/07.
//  Copyright © 2015年 SuguruSasaki. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;


// VertexShader
// 頂点の計算処理
vertex float4 myVertexShader(const device float2 * vertex_array [[ buffer(0) ]], uint vid [[ vertex_id ]]) {
    return float4(vertex_array[vid],0,1);
}

// Fragment Shader
// 各ピクセルの処理
fragment float4 myFragmentShader() {
    return float4(0.0, 0.0, 0.0, 1.0);
}



