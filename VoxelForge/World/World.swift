import Foundation

final class World {
    var chunks : [Chunk] = []
    
    init() {
        for _ in 0..<9 {
            chunks.append(TerrainGenerator.generateChunck())
        }
    }
}
