import SwiftUI

struct ContentView: View {
    private let raceScene = RaceScene()
    private let cameraRig = CameraRig()
    @State private var gameEngine: GameEngine?
    @State private var playerController: CarController?
    @State private var isThrottlePressed = false
    @State private var speed: Float = 0
    @State private var lapCount: Int = 0

    var body: some View {
        ZStack {
            if let engine = gameEngine {
                RaceView(raceScene: raceScene, cameraRig: cameraRig, gameEngine: engine)
                    .ignoresSafeArea()
            }

            // HUD overlay
            VStack {
                // Titel
                HStack {
                    Text("Racebane")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                    Spacer()

                    // Hastighed
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(Int(speed * 3.6)) km/t")
                            .font(.system(size: 20, weight: .bold, design: .monospaced))
                            .foregroundColor(speedColor)
                        Text("Omgang \(lapCount + 1)")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal, 20)
                .padding(.top, 50)

                Spacer()

                // Gas-knap
                HStack {
                    Spacer()
                    ThrottleButton(isPressed: $isThrottlePressed)
                        .padding(.trailing, 40)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            setupGame()
        }
        .onChange(of: isThrottlePressed) { newValue in
            playerController?.isThrottlePressed = newValue
        }
    }

    private var speedColor: Color {
        let ratio = speed / 15.0
        if ratio < 0.5 { return .green }
        if ratio < 0.75 { return .yellow }
        return .red
    }

    private func setupGame() {
        let engine = GameEngine(raceScene: raceScene, cameraRig: cameraRig)
        let player = engine.addCar(color: .systemPink, lane: 0)

        engine.onUpdate = { [weak player] in
            if let p = player {
                speed = p.speed
                lapCount = p.lapCount
            }
        }

        cameraRig.setupOverhead(trackPath: raceScene.trackPath)

        self.playerController = player
        self.gameEngine = engine
    }
}

#Preview {
    ContentView()
}
