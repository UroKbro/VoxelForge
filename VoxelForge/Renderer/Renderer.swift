import MetalKit

final class Renderer: NSObject, MTKViewDelegate {
    let device : MTLDevice
    let commandQueue: MTLCommandQueue
    
    init(view: MTKView) {
        guard let device = view.device else {
            fatalError("No GPU found")
        }
        
        self.device = device
        
        guard let queue = device.makeCommandQueue() else {
            fatalError("Couldn't create Queue")
        }
        
        self.commandQueue = queue
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        
        encoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}

