#include <metal_stdlib>
using namespace metal;

struct VertexOutput {
    float4 position [[position]];
};

struct PlasmaUniforms {
    float2 resolution;
    float time;
    float padding;
};

vertex VertexOutput plasmaVertex(uint vertexID [[vertex_id]])
{
    const float2 positions[] = {
        float2(-1.0, -1.0),
        float2( 3.0, -1.0),
        float2(-1.0,  3.0),
    };

    VertexOutput output;
    output.position = float4(positions[vertexID], 0.0, 1.0);
    return output;
}

fragment float4 plasmaFragment(VertexOutput input [[stage_in]],
                               constant PlasmaUniforms &uniforms [[buffer(0)]])
{
    // Metal's viewport origin is at the top-left. Shadertoy's gl_FragCoord
    // origin is at the bottom-left, so flip Y to preserve the original image.
    float2 fragCoord = float2(input.position.x, uniforms.resolution.y - input.position.y);

    // Original shader by klk: https://www.shadertoy.com/view/XsVSzW
    float time = uniforms.time;
    float2 uv = (fragCoord / uniforms.resolution.xx - 0.5) * 8.0;
    float i0 = 1.0;
    float i1 = 1.0;
    float i2 = 1.0;
    float i4 = 0.0;

    for (int iteration = 0; iteration < 7; ++iteration) {
        float2 r = float2(cos(uv.y * i0 - i4 + time / i1),
                          sin(uv.x * i0 - i4 + time / i1)) / i2;
        r += float2(-r.y, r.x) * 0.3;
        uv += r;
        i0 *= 1.93;
        i1 *= 1.15;
        i2 *= 1.7;
        i4 += 0.05 + 0.1 * time * i1;
    }

    float red = sin(uv.x - time) * 0.5 + 0.5;
    float blue = sin(uv.y + time) * 0.5 + 0.5;
    float green = sin((uv.x + uv.y + sin(time * 0.5)) * 0.5) * 0.5 + 0.5;
    return float4(red, green, blue, 1.0);
}
