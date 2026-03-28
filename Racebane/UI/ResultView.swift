import SwiftUI

/// Resultatskærm efter racet
struct ResultView: View {
    let gameState: GameState
    let onPlayAgain: () -> Void
    let onBackToMenu: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Titel
            Text(gameState.playerWon ? "DU VANDT!" : "DU TABTE!")
                .font(.system(size: 44, weight: .heavy, design: .rounded))
                .foregroundColor(gameState.playerWon ? .yellow : .red)
                .shadow(color: gameState.playerWon ? .yellow.opacity(0.5) : .red.opacity(0.5), radius: 10)

            // Tider
            VStack(spacing: 12) {
                resultRow(label: "Din tid", time: gameState.playerTotalTime, highlight: true)
                resultRow(label: "AI tid", time: gameState.aiFinished ? gameState.aiTotalTime : 0)
                resultRow(label: "Bedste omgang", time: gameState.playerBestLap, highlight: true)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.5))
            )

            // Knapper
            HStack(spacing: 20) {
                Button {
                    onPlayAgain()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Spil igen")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green)
                    )
                }

                Button {
                    onBackToMenu()
                } label: {
                    HStack {
                        Image(systemName: "house")
                        Text("Menu")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.black.opacity(0.7))
        )
    }

    private func resultRow(label: String, time: Float, highlight: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            if time > 0 && time < .infinity {
                Text(formatTime(time))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(highlight ? .yellow : .white)
            } else {
                Text("--:--.--")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
    }

    private func formatTime(_ time: Float) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let hundredths = Int((time - Float(Int(time))) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, hundredths)
    }
}
