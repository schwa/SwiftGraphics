#import "RenderKitShaders.h"

struct UnlitMaterial {
    float4 color;
    short textureIndex; // or -1 for no texture
};
