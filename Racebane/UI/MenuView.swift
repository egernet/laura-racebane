import SwiftUI
import SceneKit

/// Hovedmenu med banevælger
struct MenuView: View {
    @State private var selectedTrack: TrackDefinition?
    @State private var showPieceCatalog = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Baggrund
                LinearGradient(
                    colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.3),
                        Color(red: 0.05, green: 0.15, blue: 0.25)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    // Titel
                    VStack(spacing: 8) {
                        Text("RACEBANE")
                            .font(.system(size: 48, weight: .heavy, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red, .orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .red.opacity(0.3), radius: 10)

                        Text("Vælg din bane")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, 40)

                    // Bane-grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(TrackCatalog.allTracks, id: \.name) { track in
                                VStack(spacing: 8) {
                                    NavigationLink(value: track.name) {
                                        TrackCard(track: track)
                                    }
                                    NavigationLink(value: "mp:\(track.name)") {
                                        HStack(spacing: 4) {
                                            Image(systemName: "wifi")
                                                .font(.system(size: 11))
                                            Text("Multiplayer")
                                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                        }
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.cyan.opacity(0.15))
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    // Banestykker-knap
                    Button {
                        showPieceCatalog = true
                    } label: {
                        HStack {
                            Image(systemName: "puzzlepiece.extension")
                            Text("Banestykker")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.bottom, 30)
                }
            }
            .sheet(isPresented: $showPieceCatalog) {
                PieceCatalogView()
            }
            .navigationDestination(for: String.self) { trackName in
                if trackName.hasPrefix("mp:") {
                    let name = String(trackName.dropFirst(3))
                    if let track = TrackCatalog.allTracks.first(where: { $0.name == name }) {
                        LobbyView(trackDefinition: track)
                    }
                } else if let track = TrackCatalog.allTracks.first(where: { $0.name == trackName }) {
                    RaceContentView(trackDefinition: track)
                }
            }
        }
    }
}

/// Kort der viser en bane i menuen
struct TrackCard: View {
    let track: TrackDefinition

    var body: some View {
        VStack(spacing: 8) {
            // Mini 3D preview af banen
            TrackPreview(track: track)
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(track.name)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            // Sværhedsgrad
            HStack(spacing: 3) {
                ForEach(0..<difficultyStars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                }
                ForEach(0..<(3 - difficultyStars), id: \.self) { _ in
                    Image(systemName: "star")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow.opacity(0.3))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var difficultyStars: Int {
        switch track.name {
        case "Begynder Oval": return 1
        case "Otte-tal": return 2
        case "Grand Prix": return 3
        case "Lauras Løkke": return 2
        default: return 1
        }
    }
}

/// Mini 3D preview af en bane (top-down)
struct TrackPreview: UIViewRepresentable {
    let track: TrackDefinition

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
        scnView.antialiasingMode = .multisampling2X
        scnView.allowsCameraControl = false

        let scene = SCNScene()
        let trackPath = TrackPath(definition: track)
        let trackNode = TrackBuilder.buildTrack(from: trackPath, definition: track)
        scene.rootNode.addChildNode(trackNode)

        // Lys
        let light = SCNNode()
        light.light = SCNLight()
        light.light!.type = .directional
        light.light!.color = UIColor(white: 0.8, alpha: 1.0)
        light.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(light)

        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light!.type = .ambient
        ambient.light!.color = UIColor(white: 0.4, alpha: 1.0)
        scene.rootNode.addChildNode(ambient)

        // Kamera oppefra
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera!.usesOrthographicProjection = true

        var minX: Float = .infinity, maxX: Float = -.infinity
        var minZ: Float = .infinity, maxZ: Float = -.infinity
        for p in trackPath.points {
            let x = Float(p.position.x)
            let z = Float(p.position.z)
            minX = min(minX, x); maxX = max(maxX, x)
            minZ = min(minZ, z); maxZ = max(maxZ, z)
        }
        let cx = (minX + maxX) / 2
        let cz = (minZ + maxZ) / 2
        let span = max(maxX - minX, maxZ - minZ) + 4

        camera.camera!.orthographicScale = Double(span / 2)
        camera.position = SCNVector3(SCNFloat(cx), 50, SCNFloat(cz))
        camera.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        scene.rootNode.addChildNode(camera)

        scnView.scene = scene
        scnView.pointOfView = camera

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}
