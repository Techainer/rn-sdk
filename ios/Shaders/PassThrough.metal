/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implements a passthrough shader used for previewing content.
*/

#include <metal_stdlib>
using namespace metal;

// Vertex input/output structure for passing results from vertex shader to fragment shader
struct VertexIOPassThrought
{
    float4 position [[position]];
    float2 textureCoord [[user(texturecoord)]];
};

// Vertex shader for a textured quad
vertex VertexIOPassThrought vertexPassThrough(const device packed_float4 *pPosition  [[ buffer(0) ]],
                                  const device packed_float2 *pTexCoords [[ buffer(1) ]],
                                  uint                  vid        [[ vertex_id ]])
{
    VertexIOPassThrought outVertex;
    
    outVertex.position = pPosition[vid];
    outVertex.textureCoord = pTexCoords[vid];
    
    return outVertex;
}

// Fragment shader for a textured quad
fragment half4 fragmentPassThrough(VertexIOPassThrought         inputFragment [[ stage_in ]],
                                   texture2d<half> inputTexture  [[ texture(0) ]],
                                   sampler         samplr        [[ sampler(0) ]])
{
    return inputTexture.sample(samplr, inputFragment.textureCoord);
}
