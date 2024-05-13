import Foundation

// TODO: move

// https://docs.gl/sl4/step
// https://www.youtube.com/watch?v=YJB1QnEmlTs

public func step<V: BinaryFloatingPoint>(_ x: V, _ a: V) -> V {
    x < a ? 0.0 : 1.0
}

public func clamp<V: BinaryFloatingPoint>(_ x: V, _ a: V, _ b: V) -> V {
    if x < a {
        return a
    }
    if x > b {
        return b
    }
    return x
}

public func saturate<V: BinaryFloatingPoint>(_ x: V) -> V {
    clamp(x, 0.0, 1.0)
}

public func smoothstep<V: BinaryFloatingPoint>(_ a: V, _ b: V, _ x: V) -> V {
    let y = saturate((x - a) / (b - a))
    return y * y * (3.0 - 2.0 * y)
}

// from https://graphtoy.com
// function clamp(x,a,b) { if( x<a ) return a; if( x>b ) return b; return x; }
// function saturate(x) { return clamp(x,0.0,1.0); }
// function remap(a,b,x,c,d) { if( x<a ) return c; if( x>b ) return d; let y=(x-a)/(b-a); return c + (d-c)*y; }
// function smoothstep(a,b,x) { let y = saturate((x-a)/(b-a)); return y*y*(3.0-2.0*y); }
// function ssign(x) { return (x>=0.0)?1.0:-1.0; }
// function radians(degrees) { return degrees*Math.PI/180.0; }
// function degrees(radians) { return radians*180.0/Math.PI; }
// function inversesqrt(x) { return 1.0/Math.sqrt(x); }
// function rsqrt(x) { return inversesqrt(x); }
// function rcbrt(x) { return 1.0/Math.cbrt(x); }
// function rcp(x) { return 1.0/x; }
// function fma(x,y,z) { return x*y+z; }
// function step(a,x) { return (x<a)?0.0:1.0; }
// function mix(a,b,x) { return a + (b-a)*x; }
// function lerp(a,b,x) { return mix(a,b,x); }
// function over(x,y) { return 1.0 - (1.0-x)*(1.0-y); }
// function tri(a,x) { x = x / (2.0*Math.PI); x = x % 1.0; x = (x>0.0) ? x : x+1.0; if(x<a) x=x/a; else x=1.0-(x-a)/(1.0-a); return -1.0+2.0*x; }
// function sqr(a,x) { return (Math.sin(x)>a)?1.0:-1.0; }
// function frac(x)  { return x - Math.floor(x); }
// function fract(x) { return frac(x); }
// function exp2(x)  { return pow(2.0,x); }
// function exp10(x) { return pow(10.0,x); }
// function mod(x,y) { return x-y*Math.floor(x/y); }
// function cellnoise(x)
// {
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
// }
// function voronoi(x)
// {
//    const i = Math.floor(x);
//    const f = x - i;
//    const x0 = cellnoise(i-1); const d0 = Math.abs(f-(-1+x0));
//    const x1 = cellnoise(i  ); const d1 = Math.abs(f-(   x1));
//    const x2 = cellnoise(i+1); const d2 = Math.abs(f-( 1+x2));
//    let r = d0;
//    r = (d1<r)?d1:r;
//    r = (d2<r)?d2:r;
//    return r;
// }
// function noise(x)
// {
//    const i = Math.floor(x) | 0;
//    const f = x - i;
//    const w = f*f*f*(f*(f*6.0-15.0)+10.0);
//    const a = (2.0*cellnoise( i+0 )-1.0)*(f+0.0);
//    const b = (2.0*cellnoise( i+1 )-1.0)*(f-1.0);
//    return 2.0*(a + (b-a)*w);
// }
