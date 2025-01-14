#include <metal_stdlib>

using namespace metal;

struct VertexIn {
    float4 position [[attribute(0)]];
};

vertex float4 vertexShader(VertexIn vertex_in [[stage_in]]) {
    return vertex_in.position;
}


fragment float4 fragmentShader() {
    return float4(1.0, 0.0, 0.0, 1.0);  // Red color
}
