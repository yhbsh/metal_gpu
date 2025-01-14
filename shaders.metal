#include <metal_stdlib>
using namespace metal;


struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_cube_main(uint                 id        [[vertex_id]], 
                             const device float4 *positions [[buffer(0)]],
                             const device float4 *colors    [[buffer(1)]]) {
    VertexOut vout;
    vout.position = positions[id];
    vout.color = colors[id];
    return vout;
}

fragment float4 fragment_cube_main(float4 color [[stage_in]]) {
    return color;
}

struct VertexOutTriangle {
    float4 position [[position]];
    float3 color;
};

vertex VertexOutTriangle vertex_triangle_main(uint                 id        [[vertex_id]], 
                             const device float2 *positions [[buffer(0)]],
                             const device float3 *colors    [[buffer(1)]],
                             const device float  &time      [[buffer(2)]]) {
    VertexOutTriangle vout;
    float angle = pow(time, 2.0);
    float4x4 rotation = float4x4(cos(angle), -sin(angle), 0.0, 0.0, sin(angle), cos(angle), 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    vout.position = rotation * float4(positions[id] + float2(0.0, 0.1), 0.0, 1.0);
    vout.color = colors[id];
    return vout;
}

fragment float4 fragment_triangle_main(float3 color [[stage_in]]) {
    return float4(color, 1.0);
}
