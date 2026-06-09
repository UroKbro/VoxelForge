import Foundation

final class World {
    var chunks : [Chunk] = []
    
    init() {
        chunks.append(TerrainGenerator.generateChunck())
    }
}
