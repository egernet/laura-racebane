import SwiftUI
import MultipeerConnectivity

/// Lobby til multiplayer - find og forbind med andre spillere
struct LobbyView: View {
    let trackDefinition: TrackDefinition
    @StateObject private var session = SessionManager()
    @State private var isHosting = false
    @State private var isJoining = false
    @State private var startGame = false
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

            VStack(spacing: 24) {
                Text("Multiplayer")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)

                Text(trackDefinition.name)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                if !isHosting && !isJoining {
                    // Vælg rolle
                    chooseRoleSection
                } else if isHosting {
                    hostSection
                } else {
                    joinSection
                }

                Spacer()

                Button("Tilbage") {
                    session.disconnect()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 30)
            }
            .padding(.top, 60)
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $startGame) {
            MultiplayerRaceView(
                trackDefinition: trackDefinition,
                session: session,
                isHost: isHosting
            )
        }
    }

    // MARK: - Sections

    private var chooseRoleSection: some View {
        VStack(spacing: 16) {
            Button {
                session.startHosting()
                isHosting = true
            } label: {
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                    Text("Opret spil")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue))
            }

            Button {
                session.startBrowsing()
                isJoining = true
            } label: {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Find spil")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
            }
        }
        .padding(.horizontal, 40)
    }

    private var hostSection: some View {
        VStack(spacing: 16) {
            Text("Venter på spillere...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            // Forbundne spillere
            ForEach(session.connectedPeers, id: \.displayName) { peer in
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.green)
                    Text(peer.displayName)
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
            }

            if !session.connectedPeers.isEmpty {
                Button {
                    startGame = true
                } label: {
                    Text("START RACE!")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.red))
                }
            }
        }
        .padding(.horizontal, 30)
    }

    private var joinSection: some View {
        VStack(spacing: 16) {
            Text("Søger efter spil...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            if session.discoveredHosts.isEmpty {
                ProgressView()
                    .tint(.white)
                    .padding()
            }

            ForEach(session.discoveredHosts, id: \.displayName) { host in
                Button {
                    session.joinHost(host)
                } label: {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.blue)
                        Text(host.displayName)
                            .foregroundColor(.white)
                        Spacer()
                        Text("Forbind")
                            .foregroundColor(.blue)
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.1)))
                }
            }

            if session.isConnected {
                Text("Forbundet! Venter på at host starter...")
                    .foregroundColor(.green)
                    .padding()
            }
        }
        .padding(.horizontal, 30)
    }
}

/// Multiplayer race view (placeholder - genbruger RaceContentView-logik)
struct MultiplayerRaceView: View {
    let trackDefinition: TrackDefinition
    let session: SessionManager
    let isHost: Bool
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // For nu: brug standard race view
        // I fuld implementering ville host/client engine blive brugt her
        RaceContentView(trackDefinition: trackDefinition)
            .onDisappear {
                session.disconnect()
            }
    }
}
