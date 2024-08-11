#import <simd/simd.h>

#if __METAL_VERSION__
#import <metal_stdlib>
#import <metal_math>
#endif

#import "Support_Common.h"
#import "Support_GLSLCompat.h"
#import "Support_KellyColor.h"
#import "Support_Random.h"
#import "Support_SRGB.h"

#import "DebugShaders.h"
#import "DiffuseShadingShaders.h"
#import "PointCloudShader.h"
#import "SimplePBRShader.h"
#import "UnlitShader.h"
