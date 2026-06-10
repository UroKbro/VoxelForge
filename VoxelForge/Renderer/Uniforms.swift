import simd

struct Uniforms {

    var modelMatrix: matrix_float4x4
    var viewMatrix: matrix_float4x4
    var projectionMatrix: matrix_float4x4
    var lightDirection: SIMD3<Float>
    var ambientStrength: Float
}
