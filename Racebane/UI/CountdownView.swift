import SwiftUI

/// Nedtælling 3-2-1-GO overlay
struct CountdownView: View {
    let number: Int? // nil = GO!
    let isRacing: Bool

    @State private var scale: CGFloat = 2.0
    @State private var opacity: Double = 0.0

    var body: some View {
        if let n = number {
            Text("\(n)")
                .font(.system(size: 120, weight: .heavy, design: .rounded))
                .foregroundColor(colorForNumber(n))
                .shadow(color: .black.opacity(0.5), radius: 10)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear { animate() }
                .onChange(of: number) { _ in animate() }
        } else if isRacing {
            Text("KØR!")
                .font(.system(size: 80, weight: .heavy, design: .rounded))
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.5), radius: 15)
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear { animateGo() }
        }
    }

    private func colorForNumber(_ n: Int) -> Color {
        switch n {
        case 3: return .red
        case 2: return .yellow
        case 1: return .green
        default: return .white
        }
    }

    private func animate() {
        scale = 2.0
        opacity = 0.0
        withAnimation(.easeOut(duration: 0.3)) {
            scale = 1.0
            opacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.3).delay(0.5)) {
            opacity = 0.3
        }
    }

    private func animateGo() {
        scale = 2.0
        opacity = 0.0
        withAnimation(.easeOut(duration: 0.2)) {
            scale = 1.0
            opacity = 1.0
        }
        withAnimation(.easeIn(duration: 0.5).delay(0.5)) {
            scale = 0.5
            opacity = 0.0
        }
    }
}
