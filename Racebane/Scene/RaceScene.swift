import SceneKit

/// Opsætning af hele 3D-scenen med bane, lys og miljø
class RaceScene {
    let scene: SCNScene
    let trackNode: SCNNode
    let trackPath: TrackPath

    init(trackDefinition: TrackDefinition = TrackCatalog.beginnerOval) {
        scene = SCNScene()

        // Byg bane
        trackPath = TrackPath(definition: trackDefinition)
        trackNode = TrackBuilder.buildTrack(from: trackPath, definition: trackDefinition)
        scene.rootNode.addChildNode(trackNode)

        // Grundflade (grønt græs)
        setupGround()

        // Lys
        setupLighting()

        // Himmel
        setupSky()
    }

    private func setupGround() {
        let ground = SCNFloor()
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.2, green: 0.6, blue: 0.15, alpha: 1.0)
        material.roughness.contents = 0.9
        ground.materials = [material]
        ground.reflectivity = 0

        let groundNode = SCNNode(geometry: ground)
        scene.rootNode.addChildNode(groundNode)
    }

    private func setupLighting() {
        // Hovedlys (sol)
        let sunNode = SCNNode()
        sunNode.light = SCNLight()
        sunNode.light!.type = .directional
        sunNode.light!.color = UIColor(white: 0.9, alpha: 1.0)
        sunNode.light!.castsShadow = true
        sunNode.light!.shadowRadius = 3
        sunNode.light!.shadowSampleCount = 8
        sunNode.eulerAngles = SCNVector3(-Float.pi / 3, Float.pi / 4, 0)
        scene.rootNode.addChildNode(sunNode)

        // Ambient lys
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light!.type = .ambient
        ambientNode.light!.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambientNode)
    }

    private func setupSky() {
        scene.background.contents = UIColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1.0)
    }
}
