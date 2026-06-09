#include <metal_stdlib>

using namespace metal;

struct Vertex
{
    float3 position;
    float4 color;
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
};

struct Uniforms
{
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut vertexMain(
    const device Vertex* vertices [[buffer(0)]],
    const device Uniforms& uniforms [[buffer(1)]],
    uint vertexID [[vertex_id]]
)
{
    VertexOut out;

    float4 position = float4(vertices[vertexID].position, 1.0);
    out.position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position;

    out.color = vertices[vertexID].color;

    return out;
}

fragment float4 fragmentMain(
    VertexOut in [[stage_in]]
)
{
    return in.color;
}
