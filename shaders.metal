#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

vertex VertexOut vertex_cube_main(uint                 id        [[vertex_id]], 
                                  const device float4 *positions [[buffer(0)]],
                                  const device float4 *colors    [[buffer(1)]],
                                  constant float      &angle     [[buffer(2)]]) {
    VertexOut vout;

    const float PI = 3.1415926535897932384626433832795;
    float theta = fmod(angle, PI);

    float4x4 rotateX = float4x4(
        float4(+1.0, +0.0,        +0.0,         +0.0),
        float4(+0.0, +cos(theta), -sin(theta), +0.0),
        float4(+0.0, +sin(theta), +cos(theta), +0.0),
        float4(+0.0, +0.0,        +0.0,         +1.0)
    );

    float4x4 rotateY = float4x4(
        float4(+cos(theta), +0.0, +sin(theta), +0.0),
        float4(+0.0,        +1.0, +0.0,         +0.0),
        float4(-sin(theta), +0.0, +cos(theta), +0.0),
        float4(+0.0,        +0.0, +0.0,         +1.0)
    );

    float4x4 rotateZ = float4x4(
        float4(+cos(theta), -sin(theta), +0.0, +0.0),
        float4(+sin(theta), +cos(theta), +0.0, +0.0),
        float4(+0.0,        +0.0,        +1.0, +0.0),
        float4(+0.0,        +0.0,        +0.0, +1.0)
    );

    float4x4 matrix = rotateZ * rotateY * rotateX;
    //float4x4 matrix = rotateZ;

    vout.position = matrix * positions[id];
    vout.color = colors[id / 4];

    return vout;
}

fragment float4 fragment_cube_main(float4 color [[stage_in]]) {
    return color;
}
