#import "RenderKitShaders.h"

#ifdef __METAL_VERSION__

namespace PointCloud {

struct VertexOut {
    float4 position [[position]];
};

[[vertex]]
VertexOut PointCloudVertexShader(
                                 VertexIn in [[stage_in]],
                                 ushort instance_id[[instance_id]]
                                 )
{
    return {
        .position = { 0, 0, 0, 0 }
    };
}
//
//[[fragment]]
//vector_float4 PointCloudFragmentShader(
//                                       VertexOut in [[stage_in]]
//                                       )
//{
//    return { 1, 0, 1, 1 };
//}
}

#endif
