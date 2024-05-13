#import "RenderKitShaders.h"
#import "MetalSupport.h"

#ifdef __METAL_VERSION__
struct SimpleVertex {
    float3 position [[attribute(0)]];
    float3 normal [[attribute(1)]];
    float2 textureCoordinate [[attribute(2)]];
};
#else
#endif

struct ModelTransforms {
    float4x4 modelViewMatrix; // model space -> camera space
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
};

// TODO: DEPRECATE
struct ModelUniforms {
    float4x4 modelViewMatrix; // model space -> camera space
    float3x3 modelNormalMatrix; // model space - used for non-uniform scaled normal transformation. See https://www.youtube.com/watch?v=esC1HnyD9Bk&list=PLplnkTzzqsZS3R5DjmCQsqupu43oS9CFN
    float4 color;
};

struct CameraUniforms {
    float4x4 projectionMatrix;
};

struct LightUniforms {
    // Per diffuse light
    float3 lightPosition;
    float3 lightColor;
    float lightPower;
    // Per environment
    float3 ambientLightColor;
};
