#include <metal_stdlib>

using namespace metal;

struct VertexOut {

    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertexMain(
    uint vertexID [[vertex_id]]
) {

    float4 positions[3] = {

        float4(-0.5, -0.5, 0, 1),
        float4( 0.5, -0.5, 0, 1),
        float4( 0.0,  0.5, 0, 1)
    };

    VertexOut out;

    out.position = positions[vertexID];

    out.color = float4(
        0.3,
        0.8,
        1.0,
        1.0
    );

    return out;
}

fragment float4 fragmentMain(
    VertexOut in [[stage_in]]
) {

    return in.color;
}
