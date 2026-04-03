import SwiftUI

/// Multiplayer hovedmenu: Start eller Join
struct MultiplayerMenuView: View {
    @State private var showJoin = false
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
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
                Text("Multiplayer")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cyan, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .cyan.opacity(0.3), radius: 10)
                    .padding(.top, 60)

                Spacer()

                VStack(spacing: 16) {
                    NavigationLink(value: "mp-host-setup") {
                        HStack(spacing: 12) {
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Start spil")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Text("Vær host og inviter spillere")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cyan.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }

                    Button {
                        showJoin = true
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Join spil")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                Text("Find og deltag i et spil")
                                    .font(.system(size: 13, design: .rounded))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 30)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("Tilbage")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showJoin) {
            JoinView()
        }
    }
}
