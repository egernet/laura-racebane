import SwiftUI
import SceneKit

/// SwiftUI view der viser 3D-racerbanen
struct RaceView: UIViewRepresentable {
    let raceScene: RaceScene
    let cameraRig: CameraRig
    let gameEngine: GameEngine

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = raceScene.scene
        scnView.pointOfView = cameraRig.cameraNode
        scnView.backgroundColor = UIColor.black
        scnView.antialiasingMode = .multisampling4X
        scnView.allowsCameraControl = false
        scnView.showsStatistics = false
        scnView.delegate = gameEngine
        scnView.isPlaying = true

        // Tilføj kamera til scenen
        raceScene.scene.rootNode.addChildNode(cameraRig.cameraNode)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
