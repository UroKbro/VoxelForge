import Foundation

struct Voxel {
    var type: UInt8
    
    static let air: UInt8 = 0
    static let grass: UInt8 = 1
    static let dirt: UInt8 = 2
    static let stone: UInt8 = 3
    static let sand: UInt8 = 4
}
