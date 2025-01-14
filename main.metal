#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float time;
};

vertex VertexOut vert_main(uint vertexID [[vertex_id]], constant Uniforms &uniforms [[buffer(0)]]) {
    float angle = uniforms.time;
    float4 positions[3] = {
        float4( 0.0,  0.5, 0.0, 1.0),
        float4(-0.5, -0.5, 0.0, 1.0),
        float4( 0.5, -0.5, 0.0, 1.0)
    };

    float4 colors[3] = {
        float4(1.0, 0.0, 0.0, 1.0),
        float4(0.0, 1.0, 0.0, 1.0),
        float4(0.0, 0.0, 1.0, 1.0)
    };

    float2x2 rotation = float2x2(cos(angle), -sin(angle),
                                 sin(angle),  cos(angle));

    VertexOut out;
    out.position.xy = rotation * positions[vertexID].xy;
    out.position.zw = positions[vertexID].zw;
    out.color = colors[vertexID];
    return out;
}

fragment float4 frag_main(VertexOut in [[stage_in]]) {
    return in.color;
}


