import SwiftUI

/// Host opsætning: vælg mode (Normal/AR) og bane
struct HostSetupView: View {
    @State private var isAR = false
    @State private var selectedTrack: TrackDefinition?
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
                Text("Start spil")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)

                // Mode-vælger
                if ARSupport.isSupported {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spiltype")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Picker("Mode", selection: $isAR) {
                            Text("Normal").tag(false)
                            Text("AR").tag(true)
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.horizontal, 20)
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
                    .padding(.horizontal, 20)
                }

                // Banevælger
                Text("Vælg bane")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)

                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(TrackCatalog.allTracks, id: \.name) { track in
                            NavigationLink(value: "mp-lobby:\(track.name):\(isAR ? "ar" : "normal")") {
                                TrackCard(track: track)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

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
    }
}
