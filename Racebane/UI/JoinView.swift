import SwiftUI

/// Client-view: søger efter og joiner et multiplayer spil
struct JoinView: View {
    @StateObject private var session = SessionManager()
    @State private var startGame = false
    @State private var trackDefinition: TrackDefinition?
    @State private var isAR = false
    @State private var selectedGame: SessionManager.DiscoveredGame?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        if startGame, let track = trackDefinition {
            MultiplayerRaceView(
                trackDefinition: track,
                session: session,
                isHost: false,
                isAR: isAR
            )
        } else {
            browseView
        }
    }

    private var browseView: some View {
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
                Text("Join spil")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 60)

                if !session.isConnected {
                    if session.discoveredGames.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(.white)
                            Text("Søger efter spil...")
                                .font(.system(size: 16, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding()
                    } else {
                        VStack(spacing: 12) {
                            Text("Tilgængelige spil")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            ForEach(session.discoveredGames, id: \.peer.displayName) { game in
                                Button {
                                    selectedGame = game
                                    isAR = game.isAR
                                    session.joinHost(game.peer)
                                } label: {
                                    HStack {
                                        Image(systemName: game.isAR ? "arkit" : "antenna.radiowaves.left.and.right")
                                            .foregroundColor(game.isAR ? .orange : .blue)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(game.peer.displayName)
                                                .foregroundColor(.white)
                                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            HStack(spacing: 4) {
                                                Text(game.trackName)
                                                Text(game.isAR ? "(AR)" : "(Normal)")
                                            }
                                            .foregroundColor(.white.opacity(0.6))
                                            .font(.system(size: 13, design: .rounded))
                                        }
                                        Spacer()
                                        Text("Forbind")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 14, weight: .medium))
                                    }
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                                }
                            }
                        }
                        .padding(.horizontal, 30)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("Forbundet!")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Venter på at host starter...")
                            .font(.system(size: 16, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding()
                }

                Spacer()

                Button("Annuller") {
                    session.disconnect()
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            session.startBrowsing()
            session.onMessageReceived = { message, _ in
                if case .lobbyUpdate(let lobby) = message, lobby.isStarting {
                    if let name = lobby.trackName,
                       let track = TrackCatalog.track(named: name) {
                        trackDefinition = track
                        if let game = selectedGame {
                            isAR = game.isAR
                        }
                        startGame = true
                    }
                }
            }
        }
        .onChange(of: session.isConnected) { connected in
            // AR-client går direkte ind i AR-mode ved forbindelse
            if connected && isAR, let game = selectedGame,
               let track = TrackCatalog.track(named: game.trackName) {
                trackDefinition = track
                startGame = true
            }
        }
    }
}
