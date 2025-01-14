#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float2 position;
    packed_float3 color;
};

struct VertexOut {
    float4 position [[position]];
    float3 color;
};

vertex VertexOut vert_main(const device VertexIn* v_in [[buffer(0)]], unsigned int vid [[vertex_id]], constant float &time [[buffer(1)]]) {
    VertexOut vout;
    float angle = time;
    float4x4 rotation = float4x4(cos(angle), -sin(angle), 0.0, 0.0, sin(angle), cos(angle), 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);

    vout.position = rotation * float4(v_in[vid].position, 0.0, 1.0);
    vout.color = v_in[vid].color;
    return vout;
}

fragment float4 frag_main(float3 color [[stage_in]]) {
    return float4(color, 1.0);
}
