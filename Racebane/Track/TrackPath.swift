import SceneKit

/// Et punkt på banen med position, retning og kurvatur
struct PathPoint {
    let position: SCNVector3
    let tangent: SCNVector3
    let normal: SCNVector3
    let right: SCNVector3
    let curvatureRadius: Float
    let distance: Float
}

/// Sampler en TrackDefinition til en array af jævnt fordelte PathPoints
class TrackPath {
    let points: [PathPoint]
    let totalLength: Float
    let isClosed: Bool

    init(definition: TrackDefinition) {
        var sampledPoints: [PathPoint] = []

        var posX: Float = 0
        var posZ: Float = 0
        var heading: Float = 0 // radianer i XZ-planet
        var dist: Float = 0

        for segment in definition.segments {
            switch segment {
            case .straight(let length):
                let steps = max(Int(ceil(length / 0.1)), 1)
                let stepLen = length / Float(steps)

                for _ in 0..<steps {
                    let tx = cos(heading)
                    let tz = sin(heading)
                    let rx = -sin(heading)
                    let rz = cos(heading)

                    sampledPoints.append(PathPoint(
                        position: SCNVector3(SCNFloat(posX), 0, SCNFloat(posZ)),
                        tangent: SCNVector3(SCNFloat(tx), 0, SCNFloat(tz)),
                        normal: SCNVector3(0, 1, 0),
                        right: SCNVector3(SCNFloat(rx), 0, SCNFloat(rz)),
                        curvatureRadius: .infinity,
                        distance: dist
                    ))

                    posX += tx * stepLen
                    posZ += tz * stepLen
                    dist += stepLen
                }

            case .curve(let angle, let radius):
                let arcLength = abs(angle) * radius
                let steps = max(Int(ceil(arcLength / 0.1)), 1)
                let stepAngle = angle / Float(steps)
                let dir: Float = angle > 0 ? 1 : -1

                // Centrum af dreje-cirklen
                let cX = posX + (-sin(heading) * dir) * radius
                let cZ = posZ + (cos(heading) * dir) * radius

                for i in 0..<steps {
                    let a = Float(i) * stepAngle
                    let h = heading + a

                    let px = cX + (sin(h) * dir) * radius
                    let pz = cZ + (-cos(h) * dir) * radius

                    let tx = cos(h)
                    let tz = sin(h)
                    let rx = -sin(h)
                    let rz = cos(h)

                    sampledPoints.append(PathPoint(
                        position: SCNVector3(SCNFloat(px), 0, SCNFloat(pz)),
                        tangent: SCNVector3(SCNFloat(tx), 0, SCNFloat(tz)),
                        normal: SCNVector3(0, 1, 0),
                        right: SCNVector3(SCNFloat(rx), 0, SCNFloat(rz)),
                        curvatureRadius: radius,
                        distance: dist + abs(a) * radius
                    ))
                }

                // Opdater efter kurven
                heading += angle
                posX = cX + (sin(heading) * dir) * radius
                posZ = cZ + (-cos(heading) * dir) * radius
                dist += arcLength
            }
        }

        self.points = sampledPoints
        self.totalLength = dist
        self.isClosed = true
    }

    /// Hent PathPoint ved progress (0.0 til 1.0)
    func pointAt(progress: Float) -> PathPoint {
        guard !points.isEmpty else {
            return PathPoint(
                position: SCNVector3Zero,
                tangent: SCNVector3(1, 0, 0),
                normal: SCNVector3(0, 1, 0),
                right: SCNVector3(0, 0, 1),
                curvatureRadius: .infinity,
                distance: 0
            )
        }

        var p = progress.truncatingRemainder(dividingBy: 1.0)
        if p < 0 { p += 1.0 }

        let targetDist = p * totalLength

        // Binær søgning for effektivitet
        var lo = 0
        var hi = points.count - 1
        while lo < hi {
            let mid = (lo + hi) / 2
            if points[mid].distance < targetDist {
                lo = mid + 1
            } else {
                hi = mid
            }
        }

        return points[lo]
    }

    /// Position for et bestemt spor ved given progress
    func lanePosition(progress: Float, lane: Int, laneWidth: Float) -> SCNVector3 {
        let point = pointAt(progress: progress)
        let offset = SCNFloat(Float(lane) * laneWidth - laneWidth * 0.5)
        return point.position + point.right * offset
    }
}
