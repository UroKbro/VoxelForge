import simd

struct Camera {

    var position = SIMD3<Float>(
        0,
        5,
        15
    )

    var rotation = SIMD3<Float>(
        0,
        0,
        0
    )

    var moveSpeed: Float = 5.0

    var rotationSpeed: Float = 1.5
}
