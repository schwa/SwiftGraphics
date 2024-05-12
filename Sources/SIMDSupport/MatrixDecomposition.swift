import ApproximateEquality
import simd

// https://callumhay.blogspot.com/2010/10/decomposing-affine-transforms.html
// https://caff.de/posts/4X4-matrix-decomposition/
// https://math.stackexchange.com/questions/237369/given-this-transformation-matrix-how-do-i-decompose-it-into-translation-rotati
// https://github.com/g-truc/glm/blob/b3f87720261d623986f164b2a7f6a0a938430271/glm/gtx/matrix_decompose.inl

public func isApproximatelyEqual(_ lhs: SIMD3<Float>, _ rhs: SIMD3<Float>, epsilon: Float) -> Bool {
    let difference = abs(lhs - rhs)
    return (0 ..< 3).allSatisfy({ difference[$0] < epsilon })
}

public func isApproximatelyEqual(_ lhs: simd_float3x3, _ rhs: simd_float3x3, epsilon: Float) -> Bool {
    zip(lhs.scalars, rhs.scalars).allSatisfy({ abs($0 - $1) < epsilon })
}

public func isApproximatelyEqual(_ lhs: simd_float4x4, _ rhs: simd_float4x4, epsilon: Float) -> Bool {
    zip(lhs.scalars, rhs.scalars).allSatisfy({ abs($0 - $1) < epsilon })
}

public extension simd_float4x4 {
    var translation: SIMD3<Float> {
        columns.3.xyz
    }

    // TODO: We need an "isApproxAffine" because this can fail just due to float math
    var isAffine: Bool {
        // First make sure the bottom row meets the condition that it is (0, 0, 0, 1)
        guard rows.3 == [0, 0, 0, 1] else {
            return false
        }
        // Get the inverse of this matrix:
        // Make sure the matrix is invertible to begin with...
        guard abs(determinant) > Float.ulpOfOne else {
            return false
        }
        // Calculate the inverse and seperate the inverse translation component
        // and the top 3x3 part of the inverse matrix
        let inv4x4Matrix = inverse
        let inv4x4Translation = inv4x4Matrix.columns.3.xyz
        let inv4x4Top3x3 = simd_float3x3(truncating: inv4x4Matrix)
        // Grab just the top 3x3 matrix
        let top3x3Matrix = simd_float3x3(truncating: self)
        let invTop3x3Matrix = top3x3Matrix.inverse
        let inv3x3Translation = -(invTop3x3Matrix * translation)
        // Make sure we adhere to the conditions of a 4x4 invertible affine transform matrix
        if !SIMDSupport.isApproximatelyEqual(inv4x4Top3x3, invTop3x3Matrix, epsilon: .ulpOfOne) {
            return false
        }
        if !SIMDSupport.isApproximatelyEqual(inv4x4Translation, inv3x3Translation, epsilon: .ulpOfOne) {
            return false
        }
        return true
    }

    // Extract the rotation component via polar decomposition
    var polarDecompose: simd_float4x4 {
        var copy = self
        copy.columns.3 = [0, 0, 0, 1]
        // Extract the rotation component - this is done using polar decompostion, where
        // we successively average the matrix with its inverse transpose until there is
        // no/a very small difference between successive averages
        var norm: Float = 0
        var rotation = copy
        repeat {
            let currInvTranspose = rotation.transpose.inverse
            var nextRotation = simd_float4x4()
            // Go through every component in the matrices and find the next matrix
            for i in 0 ..< 4 {
                for j in 0 ..< 4 {
                    nextRotation[i, j] = 0.5 * (rotation[i, j] + currInvTranspose[i, j])
                }
            }
            norm = 0.0
            for i in 0 ..< 4 {
                let n = abs(rotation[i, 0] - nextRotation[i, 0]) + abs(rotation[i, 1] - nextRotation[i, 1]) + abs(rotation[i, 2] - nextRotation[i, 2])
                norm = max(norm, n)
            }
            rotation = nextRotation
        }
        while norm > Float.ulpOfOne
        return rotation
    }

    var decompose: (scale: SIMD3<Float>, rotation: simd_float4x4, translation: SIMD3<Float>) {
        // Copy the matrix first - we'll use this to break down each component
        var copy = self
        // Start by extracting the translation (and/or any projection) from the given matrix
        let translation = copy.translation
        copy.columns.3 = [0, 0, 0, 1]
        // Extract the rotation component - this is done using polar decompostion, where
        // we successively average the matrix with its inverse transpose until there is
        // no/a very small difference between successive averages
        var norm: Float = 0
        var lastNorm = norm
        var rotation = copy
        repeat {
            let currInvTranspose = rotation.transpose.inverse
            var nextRotation = simd_float4x4()
            // Go through every component in the matrices and find the next matrix
            for i in 0 ..< 4 {
                for j in 0 ..< 4 {
                    nextRotation[i, j] = 0.5 * (rotation[i, j] + currInvTranspose[i, j])
                }
            }
            norm = 0.0
            for i in 0 ..< 4 {
                let n = abs(rotation[i, 0] - nextRotation[i, 0]) + abs(rotation[i, 1] - nextRotation[i, 1]) + abs(rotation[i, 2] - nextRotation[i, 2])
                norm = max(norm, n)
            }
            rotation = nextRotation
            if norm > Float.ulpOfOne && lastNorm == norm {
                // Failing to converge. As a precaution bail.
                break
                // return (scale: .one, rotation: .identity, translation: translation)
            }
            lastNorm = norm
        }
        while norm > Float.ulpOfOne

        // The scale is simply the removal of the rotation from the non-translated matrix
        let scaleMatrix = rotation.inverse * copy
        var scale = SIMD3<Float>(scaleMatrix[0, 0], scaleMatrix[1, 1], scaleMatrix[2, 2])

        // Calculate the normalized rotation matrix and take its determinant to determine whether
        // it had a negative scale or not...
        let row1 = SIMD3<Float>(copy[0, 0], copy[0, 1], copy[0, 2]).normalized
        let row2 = SIMD3<Float>(copy[1, 0], copy[1, 1], copy[1, 2]).normalized
        let row3 = SIMD3<Float>(copy[2, 0], copy[2, 1], copy[2, 2]).normalized
        let nRotation = simd_float3x3(row1, row2, row3)

        // Special consideration: if there's a single negative scale
        // (all other combinations of negative scales will
        // be part of the rotation matrix), the determinant of the
        // normalized rotation matrix will be < 0.
        // If this is the case we apply an arbitrary negative to one
        // of the component of the scale.
        let determinant = nRotation.determinant
        if determinant < 0.0 {
            scale.x *= -1
        }

        scale.x = scale.x.isApproximatelyEqual(to: 1.0, absoluteTolerance: .ulpOfOne) ? 1 : scale.x
        scale.y = scale.x.isApproximatelyEqual(to: 1.0, absoluteTolerance: .ulpOfOne) ? 1 : scale.y
        scale.z = scale.x.isApproximatelyEqual(to: 1.0, absoluteTolerance: .ulpOfOne) ? 1 : scale.z

        return (scale: scale, rotation: rotation, translation: translation)
    }
}

public extension SRT {
    init(scale: SIMD3<Float> = .unit, rotation: simd_float4x4, translation: SIMD3<Float> = .zero) {
        let rotation = simd_quatf(rotation)
        self = SRT(scale: scale, rotation: rotation, translation: translation)
    }
}
