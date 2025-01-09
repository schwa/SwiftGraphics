import simd

// https://github.com/subokita/Arcball/blob/master/Arcball/Arcball.cpp

/**
 An tool for converting mouse movement/touches into 3D rotation
 */
public struct Arcball {
    public var size: SIMD2<Float>
    public var xAxis = true
    public var yAxis = true
    public var rollSpeed: Float = 1

    private var prevPos: SIMD3<Float>?
    private var currPos: SIMD3<Float> = [0, 0, 0]
    private var angle: Float = 0
    private var camAxis: SIMD3<Float> = [0, 1, 0]

    public init(size: SIMD2<Float>) {
        self.size = size
    }

    func toScreenCoordinate(point: SIMD2<Float>) -> SIMD3<Float> {
        var coord = SIMD3<Float>(repeating: 0)
        if xAxis {
            coord.x = (2 * point.x - size.x) / size.x
        }
        if yAxis {
            coord.y = -(2 * point.y - size.y) / size.y
        }
        coord = clamp(coord, min: [-1, -1, -1], max: [1, 1, 1])
        let length_squared = coord.x * coord.x + coord.y * coord.y
        if length_squared <= 1 {
            coord.z = sqrt(1 - length_squared)
        } else {
            coord = normalize(coord)
        }
        return coord
    }

    //    public mutating func start(point: SIMD2<Float>) {
    //        prevPos = toScreenCoordinate(point: point)
    //    }

    public mutating func update(point: SIMD2<Float>) {
        if prevPos == nil {
            prevPos = toScreenCoordinate(point: point)
        }
        currPos = toScreenCoordinate(point: point)
        angle = acos(min(1, dot(prevPos ?? currPos, currPos)))
        camAxis = cross(prevPos ?? currPos, currPos)
    }

    public mutating func reset() {
        prevPos = nil
    }

    public var viewRotation: simd_quatf {
        simd_quaternion(angle * rollSpeed, camAxis)
    }

    //    var modelRotation: simd_quatf {
    //        viewMa
    //    }
    //
    //    /**
    //     * Create rotation matrix within the world coordinate,
    //     * multiply this matrix with model matrix to rotate the object
    //     */
    //    glm::vec3 axis = glm::inverse(glm::mat3(view_matrix)) * camAxis;
    //    return glm::rotate( glm::degrees(angle) * rollSpeed, axis );
    //    }
}
