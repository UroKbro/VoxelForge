import SwiftUI
import MetalKit

struct MetalView:NSViewRepresentable {
    
    func makeNSView(context: Context) -> MTKView {
        let view = InputMTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.15, alpha: 1.0)
        view.depthStencilPixelFormat = .depth32Float
        view.preferredFramesPerSecond = 60
        view.enableSetNeedsDisplay = false
        view.isPaused = false
        
        
        let renderer = Renderer(view: view)

        view.delegate = renderer

        context.coordinator.renderer = renderer
        
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var renderer : Renderer?
    }
}

final class InputMTKView: MTKView {
    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        InputManager.shared.handleKey(event.keyCode, isDown: true)
    }

    override func keyUp(with event: NSEvent) {
        InputManager.shared.handleKey(event.keyCode, isDown: false)
    }
}
