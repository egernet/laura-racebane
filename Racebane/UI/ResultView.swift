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

            // Resultater for alle biler
            VStack(spacing: 8) {
                ForEach(Array(gameState.rankedResults.enumerated()), id: \.element.id) { position, result in
                    let isPlayer = result.id == gameState.playerIndex
                    HStack(spacing: 12) {
                        // Position
                        Text("\(position + 1).")
                            .font(.system(size: 18, weight: .bold, design: .monospaced))
                            .foregroundColor(positionColor(position))
                            .frame(width: 30, alignment: .trailing)

                        // Farve-cirkel
                        Circle()
                            .fill(Color(uiColor: result.color))
                            .frame(width: 20, height: 20)

                        // Navn
                        Text(result.name)
                            .font(.system(size: 16, weight: isPlayer ? .bold : .medium, design: .rounded))
                            .foregroundColor(isPlayer ? .yellow : .white)

                        Spacer()

                        // Tid
                        if result.finished {
                            Text(formatTime(result.totalTime))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(isPlayer ? .yellow : .white)
                        } else {
                            Text("DNF")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isPlayer ? Color.yellow.opacity(0.1) : Color.clear)
                    )
                }

                // Spillerens bedste omgang
                if gameState.playerBestLap < .infinity {
                    HStack {
                        Text("Bedste omgang")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text(formatTime(gameState.playerBestLap))
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                }
            }
            .padding(16)
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

    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .white.opacity(0.5)
        }
    }

    private func formatTime(_ time: Float) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let hundredths = Int((time - Float(Int(time))) * 100)
        return String(format: "%d:%02d.%02d", minutes, seconds, hundredths)
    }
}
