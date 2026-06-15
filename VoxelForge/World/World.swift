import Foundation

final class World {
    var chunks: [Chunk] = []
    let chunksPerAxis = 5
    
    init() {
        for chunkIndex in 0..<(chunksPerAxis * chunksPerAxis) {
            let chunkX = chunkIndex % chunksPerAxis
            let chunkZ = chunkIndex / chunksPerAxis
            chunks.append(TerrainGenerator.generateChunk(chunkX: chunkX, chunkZ: chunkZ))
        }
    }
}
