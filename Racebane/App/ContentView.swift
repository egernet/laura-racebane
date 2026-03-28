import SwiftUI

struct ContentView: View {
    private let raceScene = RaceScene()
    private let cameraRig = CameraRig()

    var body: some View {
        ZStack {
            RaceView(raceScene: raceScene, cameraRig: cameraRig)
                .ignoresSafeArea()

            // Titel overlay
            VStack {
                Text("Racebane")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)
                    .padding(.top, 50)

                Spacer()
            }
        }
        .onAppear {
            cameraRig.setupOverhead(trackPath: raceScene.trackPath)
        }
    }
}

#Preview {
    ContentView()
}
