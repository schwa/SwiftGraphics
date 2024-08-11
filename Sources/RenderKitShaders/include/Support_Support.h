#if __METAL_VERSION__
    using namespace metal;
    #define TEXTURE2D(T...) texture2d<T>
    #define CONSTANT_PTR(T) constant T*
    #define DEVICE_PTR(T) device T*
    #define SAMPLER sampler
#else
    #define TEXTURE2D(T...) uint64_t
    #define CONSTANT_PTR(T) uint64_t
    #define DEVICE_PTR(T) uint64_t
    #define SAMPLER uint64_t
#endif
