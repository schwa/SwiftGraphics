#pragma once

#include "Common.h"

struct FlatVertexShaderUniforms {
    float4x4 projectionMatrix;
    float4x4 modelViewMatrix;
    float4 baseColor;
};

struct Instance {
    float4x4 modelViewMatrix;
    float4 baseColor;
};

struct FlatFragmentShaderUniforms {
};

#define shader_name_FlatVertexShaderInstanced "FlatVertexShaderInstanced"
#define shader_name_FlatFragmentShader "FlatFragmentShader"
#define shader_name_index_id_false_color "index_id_false_color_fragment_shader"
