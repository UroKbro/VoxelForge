import Foundation

struct Chunk {
    static let size = 16
    
    var voxels:[Voxel]
    
    init() {
        voxels = Array(
            repeating: Voxel(type: 0),
            count: Self .size * Self.size * Self.size
        )
    }
    
    func index(
            x: Int,
            y: Int,
            z: Int
        ) -> Int {

            x +
            y * Self.size +
            z * Self.size * Self.size
        }

    func voxelAt(
        x: Int,
        y: Int,
        z: Int
    ) -> Voxel {

        voxels[index(x: x, y: y, z: z)]
    }

    mutating func setVoxel(
        x: Int,
        y: Int,
        z: Int,
        type: UInt8
    ) {

        voxels[
            index(x: x, y: y, z: z)
        ] = Voxel(type: type)
    }
}
