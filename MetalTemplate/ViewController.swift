//
//  ViewController.swift
//  MetalTemplate
//
//  Created by SuguruSasaki on 2015/12/05.
//  Copyright © 2015年 SuguruSasaki. All rights reserved.
//

import UIKit
import Metal
import QuartzCore



// 三角系の頂点座標
let vertexArray: [Float] = [
    0.0, 0.1,
    -0.1, -0.1,
    0.1, -0.1
]

class ViewController: UIViewController {
    
    //-------------------------------------------------------
    // Property
    //-------------------------------------------------------
  
    
    
    
    
    //-------------------------------------------------------
    // Initialize
    //-------------------------------------------------------
   
    
    
    
    
    
    //-------------------------------------------------------
    // Method
    //-------------------------------------------------------
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let device: MTLDevice! = MTLCreateSystemDefaultDevice()
        let commandQueue: MTLCommandQueue!  = device.newCommandQueue()
        
        
        // 頂点Bufferを作成
        let vertexBuffer: MTLBuffer! = device.newBufferWithBytes( vertexArray,
            length: vertexArray.count * sizeofValue(vertexArray[0]),
            options: MTLResourceOptions.OptionCPUCacheModeDefault
        )
        
        
        // Shader Library設定
        let defaultLibrary = device.newDefaultLibrary()
        let newVertexFunction = defaultLibrary!.newFunctionWithName("myVertexShader")
        let newFragmentFunction = defaultLibrary?.newFunctionWithName("myFragmentShader")
        
        
        // Pipeline記述子を作成
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction      = newVertexFunction
        pipelineStateDescriptor.fragmentFunction    = newFragmentFunction
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm // 色成分の順序を設定
        
        var pipelineState: MTLRenderPipelineState!
        do {
            pipelineState = try device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch {
            print("error with device.newRenderPipelineStateWithDescriptor")
        }
       
        
        
        let metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm   // pipeline descriptorに設定したものと同じものを設定する。
        metalLayer.frame = view.layer.frame     // フレームサイズを設定
        view.layer.addSublayer(metalLayer)
        
        
        let drawable = metalLayer.nextDrawable()
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(
            red: 1.0,
            green: 1.0,
            blue: 1.0,
            alpha: 1.0
        )
        
        
        let commandBuffer = commandQueue.commandBuffer()
        let renderEncoder: MTLRenderCommandEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        
        
        renderEncoder.drawPrimitives(.Triangle, vertexStart: 0, vertexCount: 3, instanceCount: 1); // 描画
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
        

        
    }

    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


}

