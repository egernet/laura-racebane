import SceneKit

/// En racerbil som SCNNode
class CarNode: SCNNode {

    let carColor: UIColor

    init(color: UIColor = .systemPink) {
        self.carColor = color
        super.init()
        setupCar()
    }

    required init?(coder: NSCoder) {
        self.carColor = .systemPink
        super.init(coder: coder)
        setupCar()
    }

    private func setupCar() {
        // Bil-krop
        let body = SCNBox(width: 0.3, height: 0.1, length: 0.6, chamferRadius: 0.03)
        let bodyMaterial = SCNMaterial()
        bodyMaterial.diffuse.contents = carColor
        bodyMaterial.metalness.contents = 0.3
        bodyMaterial.roughness.contents = 0.4
        body.materials = [bodyMaterial]

        let bodyNode = SCNNode(geometry: body)
        bodyNode.position = SCNVector3(0, 0.08, 0)
        addChildNode(bodyNode)

        // Kabine (top)
        let cabin = SCNBox(width: 0.22, height: 0.08, length: 0.25, chamferRadius: 0.02)
        let cabinMaterial = SCNMaterial()
        cabinMaterial.diffuse.contents = UIColor(white: 0.2, alpha: 0.8)
        cabinMaterial.metalness.contents = 0.5
        cabin.materials = [cabinMaterial]

        let cabinNode = SCNNode(geometry: cabin)
        cabinNode.position = SCNVector3(0, 0.17, -0.05)
        addChildNode(cabinNode)

        // Hjul (4 stk)
        let wheelPositions: [(Float, Float)] = [
            (-0.16, 0.2),   // Venstre for
            (0.16, 0.2),    // Højre for
            (-0.16, -0.2),  // Venstre bag
            (0.16, -0.2)    // Højre bag
        ]

        for (x, z) in wheelPositions {
            let wheel = SCNCylinder(radius: 0.05, height: 0.04)
            let wheelMaterial = SCNMaterial()
            wheelMaterial.diffuse.contents = UIColor.darkGray
            wheel.materials = [wheelMaterial]

            let wheelNode = SCNNode(geometry: wheel)
            wheelNode.position = SCNVector3(SCNFloat(x), 0.05, SCNFloat(z))
            wheelNode.eulerAngles.z = .pi / 2 // Roter så hjulet ligger rigtigt
            addChildNode(wheelNode)
        }

        // Lille lys foran
        let headlight = SCNNode()
        headlight.light = SCNLight()
        headlight.light!.type = .spot
        headlight.light!.color = UIColor.yellow
        headlight.light!.intensity = 200
        headlight.light!.spotInnerAngle = 20
        headlight.light!.spotOuterAngle = 40
        headlight.position = SCNVector3(0, 0.1, 0.35)
        headlight.eulerAngles.x = -0.1
        addChildNode(headlight)
    }

    // MARK: - Animationer

    func playFlyOffAnimation() {
        let tumble = SCNAction.rotateBy(x: .pi * 4, y: .pi * 2, z: .pi, duration: 0.6)
        let rise = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.3)
        let fall = SCNAction.moveBy(x: 0, y: -0.5, z: 0, duration: 0.3)
        let arc = SCNAction.sequence([rise, fall])
        runAction(SCNAction.group([tumble, arc]), forKey: "flyOff")
    }

    func resetFromFlyOff() {
        removeAction(forKey: "flyOff")
        eulerAngles = SCNVector3Zero
        opacity = 1.0
    }
}
