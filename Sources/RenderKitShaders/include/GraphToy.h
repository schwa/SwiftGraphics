#import <simd/simd.h>
#import <metal_stdlib>

// /Applications/Xcode-15.0.0.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/metal/ios/lib/clang/32023.35/include/metal

namespace graphtoy {

// Use metal::clamp
//template <typename T> T clamp(T x, T a, T b) {
//    if( x<a ) return a;
//    if( x>b ) return b;
//    return x;
//}

// Use metal::clamp
//template <typename T> T saturate(T x) {
//    return clamp(x, 0.0, 1.0);
//}

template <typename T> T remap(T a, T b, T x, T c, T d) {
    if (x < a) return c;
    if (x > b) return d;
    auto y = (x-a) / (b-a);
    return c + (d - c) * y;
}

// Use metal::smoothstep
//template <typename T> T smoothstep(T a, T b, T x) {
//    auto y = saturate((x-a) / (b-a));
//    return y*y*(3.0-2.0*y);
//}

// Note: unlike metal::sign 0 input is positive not NaN
template <typename T> T ssign(T x) {
    return (x >= 0.0) ? 1.0 : -1.0;
}

//template <typename T> T radians(T degrees) { return degrees * .PI/180.0; }
//template <typename T> T degrees(T radians) { return radians*180.0/Math.PI; }

template <typename T> T inversesqrt(T x) {
    return 1.0 / sqrt(x);
}

template <typename T> T rsqrt(T x) {
    return inversesqrt(x);
}

template <typename T> T rcbrt(T x) {
    return 1.0 / cbrt(x);
}

template <typename T> T rcp(T x) {
    return 1.0 / x;
}

template <typename T> T fma(T x, T y,T z) {
    return x * y + z;
}

// Use metal::step
// NOTE: Arguments seem flipped.
//template <typename T> T step(T x, T a) {
//    return x < a ? 0.0 : 1.0;
//}

// Use metal::mix
//template <typename T> T mix(T a, T b, T x) {
//    return a + (b-a)*x;
//}

template <typename T> T lerp(T a, T b, T x) {
    return mix(a,b,x);
}

template <typename T> T over(T x, T y) {
    return 1.0 - (1.0-x)*(1.0-y);
}

//template <typename T> T tri(T a,T x) { x = x / (2.0*Math.PI); x = x % 1.0; x = (x>0.0) ? x : x+1.0; if(x<a) x=x/a; else x=1.0-(x-a)/(1.0-a); return -1.0+2.0*x; }

template <typename T> T sqr(T a,T x) {
    return (sin(x)>a)?1.0:-1.0;
}

template <typename T> T frac(T x) {
    return x - floor(x);
}

template <typename T> T fract(T x) {
    return frac(x);
}

template <typename T> T exp2(T x) {
    return pow(2.0,x);
}
template <typename T> T exp10(T x) {
    return pow(10.0,x);
}

template <typename T> T mod(T x, T y) {
    return x-y*floor(x/y);
}

float cellnoise(float x)
{
    auto n = int(floor(x)) | 0;
    n = (n << 13) ^ n;  n &= 0xffffffff;
    auto m = n;
    n = n * 15731;      n &= 0xffffffff;
    n = n * m;          n &= 0xffffffff;
    n = n + 789221;     n &= 0xffffffff;
    n = n * m;          n &= 0xffffffff;
    n = n + 1376312589; n &= 0xffffffff;
    n = (n>>14) & 65535;
    return n/65535.0;
}

float voronoi(float x)
{
    const auto i = floor(x);
    const auto f = x - i;
    const auto x0 = cellnoise(i-1); const auto d0 = abs(f -(-1+x0));
    const auto x1 = cellnoise(i  ); const auto d1 = abs(f -(   x1));
    const auto x2 = cellnoise(i+1); const auto d2 = abs(f -( 1+x2));
    auto r = d0;
    r = (d1<r) ? d1 : r;
    r = (d2<r) ? d2 : r;
    return r;
}

float noise(float x)
{
    const auto i = int(floor(x)) | 0;
    const auto f = x - i;
    const auto w = f*f*f*(f*(f*6.0-15.0)+10.0);
    const auto a = (2.0*cellnoise( i+0 )-1.0)*(f+0.0);
    const auto b = (2.0*cellnoise( i+1 )-1.0)*(f-1.0);
    return 2.0*(a + (b-a)*w);
}

}



// from https://graphtoy.com
//function clamp(x,a,b) { if( x<a ) return a; if( x>b ) return b; return x; }
//function saturate(x) { return clamp(x,0.0,1.0); }
//function remap(a,b,x,c,d) { if( x<a ) return c; if( x>b ) return d; let y=(x-a)/(b-a); return c + (d-c)*y; }
//function smoothstep(a,b,x) { let y = saturate((x-a)/(b-a)); return y*y*(3.0-2.0*y); }
//function ssign(x) { return (x>=0.0)?1.0:-1.0; }
//function radians(degrees) { return degrees*Math.PI/180.0; }
//function degrees(radians) { return radians*180.0/Math.PI; }
//function inversesqrt(x) { return 1.0/Math.sqrt(x); }
//function rsqrt(x) { return inversesqrt(x); }
//function rcbrt(x) { return 1.0/Math.cbrt(x); }
//function rcp(x) { return 1.0/x; }
//function fma(x,y,z) { return x*y+z; }
//function step(a,x) { return (x<a)?0.0:1.0; }
//function mix(a,b,x) { return a + (b-a)*x; }
//function lerp(a,b,x) { return mix(a,b,x); }
//function over(x,y) { return 1.0 - (1.0-x)*(1.0-y); }
//function tri(a,x) { x = x / (2.0*Math.PI); x = x % 1.0; x = (x>0.0) ? x : x+1.0; if(x<a) x=x/a; else x=1.0-(x-a)/(1.0-a); return -1.0+2.0*x; }
//function sqr(a,x) { return (Math.sin(x)>a)?1.0:-1.0; }
//function frac(x)  { return x - Math.floor(x); }
//function fract(x) { return frac(x); }
//function exp2(x)  { return pow(2.0,x); }
//function exp10(x) { return pow(10.0,x); }
//function mod(x,y) { return x-y*Math.floor(x/y); }
//function cellnoise(x)
//{
//    let n = Math.floor(x) | 0;
//    n = (n << 13) ^ n;  n &= 0xffffffff;
//    let m = n;
//    n = n * 15731;      n &= 0xffffffff;
//    n = n * m;          n &= 0xffffffff;
//    n = n + 789221;     n &= 0xffffffff;
//    n = n * m;          n &= 0xffffffff;
//    n = n + 1376312589; n &= 0xffffffff;
//    n = (n>>14) & 65535;
//    return n/65535.0;
//}
//function voronoi(x)
//{
//    const i = Math.floor(x);
//    const f = x - i;
//    const x0 = cellnoise(i-1); const d0 = Math.abs(f-(-1+x0));
//    const x1 = cellnoise(i  ); const d1 = Math.abs(f-(   x1));
//    const x2 = cellnoise(i+1); const d2 = Math.abs(f-( 1+x2));
//    let r = d0;
//    r = (d1<r)?d1:r;
//    r = (d2<r)?d2:r;
//    return r;
//}
//function noise(x)
//{
//    const i = Math.floor(x) | 0;
//    const f = x - i;
//    const w = f*f*f*(f*(f*6.0-15.0)+10.0);
//    const a = (2.0*cellnoise( i+0 )-1.0)*(f+0.0);
//    const b = (2.0*cellnoise( i+1 )-1.0)*(f-1.0);
//    return 2.0*(a + (b-a)*w);
//}
