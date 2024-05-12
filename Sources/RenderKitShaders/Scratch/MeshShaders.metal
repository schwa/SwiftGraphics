//
//#include <metal_stdlib>
//#include <simd/simd.h>
//
//using namespace metal;
//
//struct CurvePayload {
//
//};
//
//[[object]]
//void objectShader(
//    object_data CurvePayload *payloadOutput [[payload]],
//    const device void *inputData [[buffer(0)]],
//    uint thread_index_in_threadgroup [[thread_index_in_threadgroup]],
//    uint triangleID [[threadgroup_position_in_grid]],
//    metal::mesh_grid_properties mgp
//      ushort instance_id [[instance_id]]
//
//                  )
//{
////    if (hairID < kHairsPerBlock)
////       payloadOutput[hairID] = generateCurveData(inputData, hairID, triangleID);
////    if (thread_index_in_threadgroup == 0)
////       mgp.set_threadgroups_per_grid(uint3(kHairPerBlockX, kHairPerBlockY, 1));
//}
//
//struct VertexData    { float4 position [[position]]; };
//struct PrimitiveData { float4 color; };
//
//using triangle_mesh_t = metal::mesh<
//                                    VertexData,               // Vertex type
//                                    PrimitiveData,            // Primitive type
//                                    10,                       // Maximum vertices
//                                    6,                        // Maximum primitives
//                                    metal::topology::triangle // Topology
//>;
//
//[[mesh]] void myMeshShader(triangle_mesh_t outputMesh,
//                         uint tid [[thread_index_in_threadgroup]])
//{
//
////    if (tid < kVertexCount)
////        outputMesh.set_vertex(tid, calculateVertex(tid));
////
////    if (tid < kIndexCount)
////        outputMesh.set_index(tid, calculateIndex(tid));
////
////    if (tid < kPrimitiveCount)
////        outputMesh.set_primitive(tid, calculatePrimitive(tid));
////
////if (tid == 0)
////    outputMesh.set_primitive_count(kPrimitiveCount);
//
//}
