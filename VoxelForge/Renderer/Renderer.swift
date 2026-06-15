import MetalKit
import simd

final class Renderer: NSObject, MTKViewDelegate {
    let device : MTLDevice
    let commandQueue: MTLCommandQueue
    var pipelineState: MTLRenderPipelineState?
    var depthState: MTLDepthStencilState!
    var vertexBuffer: MTLBuffer!
    var uniformBuffer: MTLBuffer!
    private var chunkMeshes: [ChunkMesh] = []
    var camera = Camera()
    var world = World()
    private var timeOfDay: Float = 0.0
    
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
        buildDepthState()
        buildPipeline()
        buildWorldMeshes()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        updateCamera()
        
        timeOfDay += 0.005
        let sunHeight = sin(timeOfDay)
        
        let skyColor: MTLClearColor
        let ambientStrength: Float
        let lightDir: SIMD3<Float>
        
        if sunHeight > 0.2 {
            let t = min(1.0, (sunHeight - 0.2) / 0.4)
            skyColor = MTLClearColor(
                red: 0.4 * Double(t) + 0.8 * Double(1.0 - t),
                green: 0.6 * Double(t) + 0.4 * Double(1.0 - t),
                blue: 0.9 * Double(t) + 0.3 * Double(1.0 - t),
                alpha: 1.0
            )
            ambientStrength = 0.35 * t + 0.25 * (1.0 - t)
            lightDir = normalize(SIMD3<Float>(cos(timeOfDay), -sunHeight, -0.2))
        } else if sunHeight > -0.2 {
            let t = (sunHeight + 0.2) / 0.4
            skyColor = MTLClearColor(
                red: 0.8 * Double(t) + 0.02 * Double(1.0 - t),
                green: 0.4 * Double(t) + 0.02 * Double(1.0 - t),
                blue: 0.3 * Double(t) + 0.08 * Double(1.0 - t),
                alpha: 1.0
            )
            ambientStrength = 0.25 * t + 0.1 * (1.0 - t)
            lightDir = normalize(SIMD3<Float>(cos(timeOfDay), -max(0.01, sunHeight), -0.2))
        } else {
            skyColor = MTLClearColor(red: 0.02, green: 0.02, blue: 0.08, alpha: 1.0)
            ambientStrength = 0.1
            lightDir = normalize(SIMD3<Float>(cos(timeOfDay), sunHeight, -0.2))
        }
        view.clearColor = skyColor

        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor
        else {
            return
        }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        guard let encoder =
            commandBuffer?.makeRenderCommandEncoder(
                descriptor: descriptor
            )
        else {
            return
        }

        guard let pipelineState else { return }
        encoder.setRenderPipelineState(pipelineState)
        encoder.setCullMode(.back)

        encoder.setDepthStencilState(depthState)

        let forward = SIMD3<Float>(
            sin(camera.yaw) * cos(camera.pitch),
            sin(camera.pitch),
            -cos(camera.yaw) * cos(camera.pitch)
        )

        var uniforms = Uniforms(
            modelMatrix: matrix_identity_float4x4,
            viewMatrix: matrix4x4_lookAt(
                eye: camera.position,
                center: camera.position + forward,
                up: SIMD3<Float>(0, 1, 0)
            ),
            projectionMatrix: matrix4x4_perspective(
                fovY: 65 * (.pi / 180),
                aspect: Float(view.drawableSize.width / max(view.drawableSize.height, 1)),
                nearZ: 0.1,
                farZ: 100
            ),
            lightDirection: lightDir,
            ambientStrength: ambientStrength
        )

        encoder.setVertexBuffer(
            uniformBuffer,
            offset: 0,
            index: 1
        )
        encoder.setFragmentBuffer(
            uniformBuffer,
            offset: 0,
            index: 1
        )
        memcpy(uniformBuffer.contents(), &uniforms, MemoryLayout<Uniforms>.stride)

        let viewProjection = uniforms.projectionMatrix * uniforms.viewMatrix

        for mesh in visibleChunkMeshes(viewProjection: viewProjection) {
            encoder.setVertexBuffer(mesh.vertexBuffer, offset: 0, index: 0)
            encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: mesh.vertexCount)
        }

        encoder.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
    func updateCamera() {

        let input = InputManager.shared

        if input.w {
            camera.position += SIMD3<Float>(sin(camera.yaw), 0, -cos(camera.yaw)) * camera.moveSpeed
        }

        if input.s {
            camera.position -= SIMD3<Float>(sin(camera.yaw), 0, -cos(camera.yaw)) * camera.moveSpeed
        }

        if input.a {
            camera.position -= SIMD3<Float>(cos(camera.yaw), 0, sin(camera.yaw)) * camera.moveSpeed
        }

        if input.d {
            camera.position += SIMD3<Float>(cos(camera.yaw), 0, sin(camera.yaw)) * camera.moveSpeed
        }

        if input.q {
            camera.yaw -= camera.rotationSpeed
        }

        if input.e {
            camera.yaw += camera.rotationSpeed
        }

        if input.up {
            camera.pitch += camera.pitchSpeed
        }

        if input.down {
            camera.pitch -= camera.pitchSpeed
        }

        camera.pitch = min(max(camera.pitch, -1.45), 1.45)
    }
    func buildPipeline() {

        guard let library = device.makeDefaultLibrary()
        else {
            fatalError("Couldn't load shader library")
        }

        let descriptor = MTLRenderPipelineDescriptor()

        descriptor.vertexFunction =
            library.makeFunction(name: "vertexMain")

        descriptor.fragmentFunction =
            library.makeFunction(name: "fragmentMain")

        descriptor.colorAttachments[0].pixelFormat =
            .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float

        do {

            pipelineState =
                try device.makeRenderPipelineState(
                    descriptor: descriptor
                )

        } catch {

            fatalError(
                "Failed pipeline creation: \(error)"
            )
        }
    }

    func buildDepthState() {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        depthState = device.makeDepthStencilState(descriptor: descriptor)
    }
    func buildWorldMeshes() {
        let chunksPerAxis = world.chunksPerAxis
        let chunkOffset = Float(Chunk.size) * Float(chunksPerAxis - 1) * 0.5
        chunkMeshes.removeAll(keepingCapacity: true)

        for (chunkIndex, chunk) in world.chunks.enumerated() {
            let chunkX = chunkIndex % chunksPerAxis
            let chunkZ = chunkIndex / chunksPerAxis
            let worldOffset = SIMD3<Float>(
                Float(chunkX * Chunk.size) - chunkOffset,
                0,
                Float(chunkZ * Chunk.size) - chunkOffset
            )

            var vertices: [Vertex] = []

            for x in 0..<Chunk.size {
                for y in 0..<Chunk.size {
                    for z in 0..<Chunk.size {
                        let voxel = chunk.voxelAt(x: x, y: y, z: z)
                        if voxel.type == 0 { continue }
                        let base = worldOffset + SIMD3<Float>(Float(x), Float(y) - 2, Float(z))
                        let color = colorFor(voxelType: voxel.type)
                        
                        let p000 = base + SIMD3<Float>(0, 0, 0)
                        let p100 = base + SIMD3<Float>(1, 0, 0)
                        let p010 = base + SIMD3<Float>(0, 1, 0)
                        let p110 = base + SIMD3<Float>(1, 1, 0)
                        let p001 = base + SIMD3<Float>(0, 0, 1)
                        let p101 = base + SIMD3<Float>(1, 0, 1)
                        let p011 = base + SIMD3<Float>(0, 1, 1)
                        let p111 = base + SIMD3<Float>(1, 1, 1)

                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x, y: y, z: z - 1) {
                            addQuad(&vertices, p000, p100, p110, p010, color, SIMD3<Float>(0, 0, 1))
                        }
                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x, y: y, z: z + 1) {
                            addQuad(&vertices, p101, p001, p011, p111, color, SIMD3<Float>(0, 0, -1))
                        }
                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x - 1, y: y, z: z) {
                            addQuad(&vertices, p001, p000, p010, p011, color, SIMD3<Float>(-1, 0, 0))
                        }
                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x + 1, y: y, z: z) {
                            addQuad(&vertices, p100, p101, p111, p110, color, SIMD3<Float>(1, 0, 0))
                        }
                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x, y: y + 1, z: z) {
                            addQuad(&vertices, p010, p110, p111, p011, color, SIMD3<Float>(0, 1, 0))
                        }
                        if !isSolid(chunkX: chunkX, chunkZ: chunkZ, x: x, y: y - 1, z: z) {
                            addQuad(&vertices, p001, p101, p100, p000, color, SIMD3<Float>(0, -1, 0))
                        }
                    }
                }
            }

            guard !vertices.isEmpty,
                  let vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count)
            else { continue }

            chunkMeshes.append(
                ChunkMesh(position: worldOffset, vertexBuffer: vertexBuffer, vertexCount: vertices.count)
            )
        }

        uniformBuffer = device.makeBuffer(
            length: MemoryLayout<Uniforms>.stride,
            options: .storageModeShared
        )
    }

    private func isSolid(chunkX: Int, chunkZ: Int, x: Int, y: Int, z: Int) -> Bool {
        if y < 0 || y >= Chunk.size { return false }
        
        var cx = chunkX
        var cz = chunkZ
        var lx = x
        var lz = z
        
        if lx < 0 {
            cx -= 1
            lx = Chunk.size - 1
        } else if lx >= Chunk.size {
            cx += 1
            lx = 0
        }
        
        if lz < 0 {
            cz -= 1
            lz = Chunk.size - 1
        } else if lz >= Chunk.size {
            cz += 1
            lz = 0
        }
        
        let chunksPerAxis = world.chunksPerAxis
        if cx < 0 || cx >= chunksPerAxis || cz < 0 || cz >= chunksPerAxis {
            return false
        }
        
        let idx = cz * chunksPerAxis + cx
        return world.chunks[idx].voxelAt(x: lx, y: y, z: lz).type != 0
    }

    private func colorFor(voxelType: UInt8) -> SIMD4<Float> {
        switch voxelType {
        case Voxel.grass:
            return SIMD4<Float>(0.2, 0.8, 0.3, 1.0)
        case Voxel.dirt:
            return SIMD4<Float>(0.5, 0.35, 0.2, 1.0)
        case Voxel.stone:
            return SIMD4<Float>(0.5, 0.5, 0.5, 1.0)
        case Voxel.sand:
            return SIMD4<Float>(0.92, 0.82, 0.6, 1.0)
        default:
            return SIMD4<Float>(1.0, 1.0, 1.0, 1.0)
        }
    }

    private func visibleChunkMeshes(viewProjection: matrix_float4x4) -> [ChunkMesh] {
        chunkMeshes.filter { mesh in
            let minPoint = mesh.position
            let maxPoint = mesh.position + SIMD3<Float>(Float(Chunk.size), Float(Chunk.size), Float(Chunk.size))
            return chunkIntersectsFrustum(minPoint: minPoint, maxPoint: maxPoint, viewProjection: viewProjection)
        }
    }

    private func chunkIntersectsFrustum(
        minPoint: SIMD3<Float>,
        maxPoint: SIMD3<Float>,
        viewProjection: matrix_float4x4
    ) -> Bool {
        let corners: [SIMD3<Float>] = [
            SIMD3<Float>(minPoint.x, minPoint.y, minPoint.z),
            SIMD3<Float>(maxPoint.x, minPoint.y, minPoint.z),
            SIMD3<Float>(minPoint.x, maxPoint.y, minPoint.z),
            SIMD3<Float>(maxPoint.x, maxPoint.y, minPoint.z),
            SIMD3<Float>(minPoint.x, minPoint.y, maxPoint.z),
            SIMD3<Float>(maxPoint.x, minPoint.y, maxPoint.z),
            SIMD3<Float>(minPoint.x, maxPoint.y, maxPoint.z),
            SIMD3<Float>(maxPoint.x, maxPoint.y, maxPoint.z)
        ]

        for corner in corners {
            let clip = viewProjection * SIMD4<Float>(corner.x, corner.y, corner.z, 1)
            if clip.w > 0 {
                let ndc = SIMD3<Float>(clip.x, clip.y, clip.z) / clip.w
                if abs(ndc.x) <= 1 && abs(ndc.y) <= 1 && abs(ndc.z) <= 1 {
                    return true
                }
            }
        }

        return false
    }

    func addQuad(_ vertices: inout [Vertex], _ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c1: SIMD3<Float>, _ d: SIMD3<Float>, _ color: SIMD4<Float>, _ normal: SIMD3<Float>) {
        vertices.append(contentsOf: [
            Vertex(position: a, color: color, normal: normal),
            Vertex(position: b, color: color, normal: normal),
            Vertex(position: c1, color: color, normal: normal),
            Vertex(position: a, color: color, normal: normal),
            Vertex(position: c1, color: color, normal: normal),
            Vertex(position: d, color: color, normal: normal)
        ])
    }
}

private struct ChunkMesh {
    let position: SIMD3<Float>
    let vertexBuffer: MTLBuffer
    let vertexCount: Int
}

private func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cos(radians)
    let st = sin(radians)
    let ci = 1 - ct

    return matrix_float4x4(columns: (
        SIMD4<Float>(ct + ci * unitAxis.x * unitAxis.x, ci * unitAxis.x * unitAxis.y + unitAxis.z * st, ci * unitAxis.x * unitAxis.z - unitAxis.y * st, 0),
        SIMD4<Float>(ci * unitAxis.x * unitAxis.y - unitAxis.z * st, ct + ci * unitAxis.y * unitAxis.y, ci * unitAxis.y * unitAxis.z + unitAxis.x * st, 0),
        SIMD4<Float>(ci * unitAxis.x * unitAxis.z + unitAxis.y * st, ci * unitAxis.y * unitAxis.z - unitAxis.x * st, ct + ci * unitAxis.z * unitAxis.z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
}

private func matrix4x4_translation(_ t: SIMD3<Float>) -> matrix_float4x4 {
    matrix_float4x4(columns: (
        SIMD4<Float>(1, 0, 0, 0),
        SIMD4<Float>(0, 1, 0, 0),
        SIMD4<Float>(0, 0, 1, 0),
        SIMD4<Float>(t.x, t.y, t.z, 1)
    ))
}

private func matrix4x4_scale(_ x: Float, _ y: Float, _ z: Float) -> matrix_float4x4 {
    matrix_float4x4(columns: (
        SIMD4<Float>(x, 0, 0, 0),
        SIMD4<Float>(0, y, 0, 0),
        SIMD4<Float>(0, 0, z, 0),
        SIMD4<Float>(0, 0, 0, 1)
    ))
}

private func matrix4x4_perspective(fovY: Float, aspect: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let yScale = 1 / tan(fovY * 0.5)
    let xScale = yScale / aspect
    let zRange = farZ - nearZ

    return matrix_float4x4(columns: (
        SIMD4<Float>(xScale, 0, 0, 0),
        SIMD4<Float>(0, yScale, 0, 0),
        SIMD4<Float>(0, 0, -(farZ + nearZ) / zRange, -1),
        SIMD4<Float>(0, 0, -(2 * farZ * nearZ) / zRange, 0)
    ))
}

private func matrix4x4_lookAt(eye: SIMD3<Float>, center: SIMD3<Float>, up: SIMD3<Float>) -> matrix_float4x4 {
    let zAxis = normalize(eye - center)
    let xAxis = normalize(cross(up, zAxis))
    let yAxis = cross(zAxis, xAxis)

    return matrix_float4x4(columns: (
        SIMD4<Float>(xAxis.x, yAxis.x, zAxis.x, 0),
        SIMD4<Float>(xAxis.y, yAxis.y, zAxis.y, 0),
        SIMD4<Float>(xAxis.z, yAxis.z, zAxis.z, 0),
        SIMD4<Float>(-dot(xAxis, eye), -dot(yAxis, eye), -dot(zAxis, eye), 1)
    ))
}
