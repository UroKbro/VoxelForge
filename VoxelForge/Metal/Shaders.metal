#include <metal_stdlib>

using namespace metal;

struct Vertex
{
    float3 position;
    float4 color;
    float3 normal;
};

struct VertexOut
{
    float4 position [[position]];
    float4 color;
    float3 normal;
};

struct Uniforms
{
    float4x4 modelMatrix;
    float4x4 viewMatrix;
    float4x4 projectionMatrix;
    float3 lightDirection;
    float ambientStrength;
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
    out.normal = vertices[vertexID].normal;

    return out;
}

fragment float4 fragmentMain(
    VertexOut in [[stage_in]]
    , const device Uniforms& uniforms [[buffer(1)]]
)
{
    float light = max(dot(normalize(in.normal), normalize(-uniforms.lightDirection)), 0.0);
    float brightness = uniforms.ambientStrength + light * (1.0 - uniforms.ambientStrength);
    return float4(in.color.rgb * brightness, in.color.a);
}
