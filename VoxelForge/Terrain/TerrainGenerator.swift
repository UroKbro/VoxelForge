import Foundation

struct TerrainGenerator {
    static func generateChunck() -> Chunk {
        var chunk = Chunk()
        for x in 0..<Chunk.size {
            for z in 0..<Chunk.size {
                let rawHeight = Int(4 + sin(Double(x) * 0.5) * 3 + cos(Double(z) * 0.5) * 3)
                let height = max(0, min(Chunk.size, rawHeight))
                
                for y in 0..<height {
                    chunk.setVoxel(x: x, y: y, z: z, type:1)
                }
            }
        }
        return chunk
    }
}
