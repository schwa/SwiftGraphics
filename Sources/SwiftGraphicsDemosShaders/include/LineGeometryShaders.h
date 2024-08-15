#import <simd/simd.h>

struct LineGeometrySegment {
    float2 start;
    float2 end;
    float width;
    float4 color;
};

#ifdef __METAL_VERSION__

#import <metal_logging>
#import <metal_mesh>
#import <metal_stdlib>

using namespace metal;

namespace LineGeometryShaders {

    struct Vertex {
        float4 position [[position]];
    };

    struct Primitive {
        float4 color;
    };

    struct FragmentIn {
        Vertex vert;
        Primitive primitive;
    };

    struct Payload {
        uint segment_indices[32];
    };

    using triangle_mesh_t = metal::mesh<Vertex, Primitive, 4, 2, metal::topology::triangle>;

    uint thread_position_in_threadgroup [[thread_position_in_threadgroup]];
    uint thread_index_in_threadgroup [[thread_index_in_threadgroup]];
    uint threadgroup_position_in_grid [[threadgroup_position_in_grid]];

    uint thread_position_in_grid [[thread_position_in_grid]];
    uint threads_per_grid [[threads_per_grid]];
uint threadgroups_per_grid [[threadgroups_per_grid]];
uint threads_per_threadgroup [[threads_per_threadgroup]];



    void log_attributes(int id) {
        if (thread_position_in_grid != 0) {
            return;
        }
        os_log_default.log("[%d] threadgroups_per_grid: %d / threads_per_threadgroup: %d / threads_per_grid: %d", id, threadgroups_per_grid, threads_per_threadgroup,  threads_per_grid);
    }

    [[object]]
    void objectShader(
        object_data Payload &payload [[payload]],
        const device LineGeometrySegment *segments [[buffer(0)]],
        constant uint &segmentCount [[buffer(1)]],
        constant float2 &drawableSize [[buffer(3)]],
        constant float &displayScale [[buffer(4)]],
        mesh_grid_properties mesh_grid_properties)
    {
        log_attributes(1);
        if (thread_position_in_grid >= segmentCount) {
            return;
        }

        payload.segment_indices[thread_position_in_grid] = thread_position_in_grid;
        if (thread_index_in_threadgroup == 0) {
//            os_log_default.log("firing off meshes…");
            mesh_grid_properties.set_threadgroups_per_grid(uint3(segmentCount, 1, 1));
        }
    }

    [[mesh]]
    void meshShader(
        object_data Payload const& payload [[payload]],
        constant float2 &drawableSize [[buffer(1)]],
        constant float &displayScale [[buffer(2)]],
        const device LineGeometrySegment *segments [[buffer(3)]],
        constant uint &segmentCount [[buffer(4)]],
        triangle_mesh_t outMesh
    ) {
        log_attributes(2);
        const uint mesh_count = 1;
        const uint primitive_count = 2;
        const uint index_count = 6;
        const uint vertex_count = 4;

        auto N = thread_index_in_threadgroup;

        if (N >= index_count) {
            return;
        }

        auto segment_index = payload.segment_indices[threadgroup_position_in_grid];

//        os_log_default.log("payload: %d, %d", payload.segment_indices[0], payload.segment_indices[1]);
//        os_log_default.log("meshShader: %d/%d %d/%d | %d", thread_index_in_threadgroup, segmentCount, threadgroup_position_in_grid, index_count, segment_index);

        const LineGeometrySegment segment = segments[segment_index];
        if (N < mesh_count) {
            outMesh.set_primitive_count(2);
        }
        if (N < primitive_count) {
            Primitive p = { .color = segment.color };
            outMesh.set_primitive(N, p);
        }
        if (N < index_count) {
            const uint indices[] = {
                0, 1, 2, 1, 2, 3
            };
            outMesh.set_index(N, indices[N]);
        }
        if (N < vertex_count) {
            const float2 vertices[] = { { 0, 0 }, { 0, 1 }, { 1, 0 }, { 1, 1 } };
            // TODO: Move this to object shader and get via payload.
            const float2 direction = segment.end - segment.start;
            const float lineLength = length(direction);
            const float2 perpendicular = normalize(float2(-direction.y, direction.x));

            float2 position = segment.start + normalize(direction) * vertices[N].x * lineLength + perpendicular * (vertices[N].y - 0.5) * segment.width;
            Vertex v;
            v.position = float4((position * 2 * displayScale / drawableSize - 1), 0, 1);
            v.position.y *= -1;
            outMesh.set_vertex(N, v);
        }
    }

    // MARK: -

    [[fragment]]
    float4 fragmentShader(
        FragmentIn in [[stage_in]]
    )
    {
        return in.primitive.color;
    }

};
#endif
