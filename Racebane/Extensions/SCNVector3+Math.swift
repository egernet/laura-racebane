import SceneKit

#if os(macOS)
typealias SCNFloat = CGFloat
#else
typealias SCNFloat = Float
#endif

extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        SCNVector3(left.x + right.x, left.y + right.y, left.z + right.z)
    }

    static func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        SCNVector3(left.x - right.x, left.y - right.y, left.z - right.z)
    }

    static func * (vector: SCNVector3, scalar: SCNFloat) -> SCNVector3 {
        SCNVector3(vector.x * scalar, vector.y * scalar, vector.z * scalar)
    }

    static func * (scalar: SCNFloat, vector: SCNVector3) -> SCNVector3 {
        vector * scalar
    }

    var length: SCNFloat {
        sqrt(x * x + y * y + z * z)
    }

    var normalized: SCNVector3 {
        let len = length
        guard len > 0 else { return SCNVector3Zero }
        return SCNVector3(x / len, y / len, z / len)
    }

    func cross(_ other: SCNVector3) -> SCNVector3 {
        SCNVector3(
            y * other.z - z * other.y,
            z * other.x - x * other.z,
            x * other.y - y * other.x
        )
    }

    func dot(_ other: SCNVector3) -> SCNFloat {
        x * other.x + y * other.y + z * other.z
    }
}
