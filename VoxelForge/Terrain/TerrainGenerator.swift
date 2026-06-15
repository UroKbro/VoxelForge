import Foundation

struct TerrainGenerator {
    static func generateChunk(chunkX: Int, chunkZ: Int) -> Chunk {
        var chunk = Chunk()
        let chunkOffset = Chunk.size
        
        for x in 0..<Chunk.size {
            let globalX = chunkX * chunkOffset + x
            for z in 0..<Chunk.size {
                let globalZ = chunkZ * chunkOffset + z
                
                let rawHeight = Int(6 + sin(Double(globalX) * 0.2) * 3 + cos(Double(globalZ) * 0.2) * 3)
                let height = max(1, min(Chunk.size, rawHeight))
                
                for y in 0..<height {
                    let type: UInt8
                    if y == height - 1 {
                        if height <= 4 {
                            type = Voxel.sand
                        } else {
                            type = Voxel.grass
                        }
                    } else if y > height - 4 {
                        type = Voxel.dirt
                    } else {
                        type = Voxel.stone
                    }
                    chunk.setVoxel(x: x, y: y, z: z, type: type)
                }
            }
        }
        return chunk
    }
}
