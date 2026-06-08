import SwiftUI
import MetalKit

struct MetalView:NSViewRepresentable {
    
    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
       
        
        let renderer = Renderer(view: view)

        view.delegate = renderer

        context.coordinator.renderer = renderer
        
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        <#code#>
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer : Renderer?
    }
}

