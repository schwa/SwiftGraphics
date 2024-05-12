#import "RenderKitShaders.h"

// TODO: Rename
struct FlatMaterial {
    float4 diffuseColor;
    short diffuseTextureIndex; // or -1 for no texture
    float4 ambientColor;
    short ambientTextureIndex; // or -1 for no texture
};
