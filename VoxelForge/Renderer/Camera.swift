import simd

struct Camera {

    var position = SIMD3<Float>(
        8,
        10,
        28
    )

    var yaw: Float = 0
    var pitch: Float = 0

    let moveSpeed: Float = 0.1

    let rotationSpeed: Float = 0.03
    let pitchSpeed: Float = 0.03
}
