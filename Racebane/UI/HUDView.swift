import SwiftUI

/// Speedometer og race-info overlay
struct HUDView: View {
    let speed: Float
    let maxSpeed: Float
    let lapCount: Int
    let dangerLevel: Float
    let isPenalty: Bool
    let penaltyProgress: Float

    var body: some View {
        VStack {
            // Top bar
            HStack {
                Text("Racebane")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4)

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    // Hastighed
                    Text("\(Int(speed * 3.6)) km/t")
                        .font(.system(size: 22, weight: .bold, design: .monospaced))
                        .foregroundColor(speedColor)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    // Omgang
                    Text("Omgang \(lapCount + 1)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)

            Spacer()

            // Fare-indikator bar (under speedometer)
            if dangerLevel > 0.3 {
                DangerBar(level: dangerLevel)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 10)
                    .transition(.opacity)
            }

            // Straf overlay
            if isPenalty {
                PenaltyOverlay(progress: penaltyProgress)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPenalty)
        .animation(.easeInOut(duration: 0.1), value: dangerLevel > 0.3)
    }

    private var speedColor: Color {
        if dangerLevel > 0.8 { return .red }
        if dangerLevel > 0.5 { return .yellow }
        return .green
    }
}

/// Fare-bar der viser hvor tæt man er på at flyve af
struct DangerBar: View {
    let level: Float

    var body: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Baggrund
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.4))

                    // Fare-niveau
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * CGFloat(min(level, 1.0)))
                }
            }
            .frame(height: 8)

            if level > 0.7 {
                Text("PAS PÅ!")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.red)
                    .shadow(color: .black.opacity(0.5), radius: 2)
            }
        }
    }

    private var barColor: LinearGradient {
        LinearGradient(
            colors: [.green, .yellow, .red],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

/// Straf-overlay når bilen flyver af banen
struct PenaltyOverlay: View {
    let progress: Float

    var body: some View {
        VStack(spacing: 8) {
            Text("AF BANEN!")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .foregroundColor(.red)
                .shadow(color: .black, radius: 4)

            // Nedtælling
            let remaining = max(0, 2.0 - 2.0 * progress)
            Text(String(format: "%.1f", remaining))
                .font(.system(size: 40, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black, radius: 4)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.red)
                        .frame(width: geo.size.width * CGFloat(progress))
                }
            }
            .frame(width: 200, height: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.6))
        )
    }
}
