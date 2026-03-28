import SwiftUI

/// Stor gas-knap til at styre bilen
struct ThrottleButton: View {
    @Binding var isPressed: Bool

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        isPressed ? Color.green : Color.green.opacity(0.7),
                        isPressed ? Color.green.opacity(0.8) : Color.green.opacity(0.3)
                    ]),
                    center: .center,
                    startRadius: 5,
                    endRadius: 60
                )
            )
            .frame(width: 120, height: 120)
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.6), lineWidth: 3)
            )
            .overlay(
                VStack(spacing: 2) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white)
                    Text("GAS")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            )
            .scaleEffect(isPressed ? 1.1 : 1.0)
            .shadow(color: isPressed ? .green.opacity(0.6) : .clear, radius: 15)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}
