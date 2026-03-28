import SwiftUI
import SceneKit

/// Katalog over alle tilgængelige banestykker
struct PieceCatalogView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
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

                ScrollView {
                    VStack(spacing: 0) {
                        // Lige stykker
                        sectionHeader("Lige stykker")
                        pieceRow(.straight)
                        pieceRow(.straightLong)
                        pieceRow(.straightShort)

                        // Standard kurver
                        sectionHeader("Standard kurver (45°)")
                        pieceRow(.curveLeft)
                        pieceRow(.curveRight)

                        // Brede kurver
                        sectionHeader("Brede kurver (45°)")
                        pieceRow(.wideCurveLeft)
                        pieceRow(.wideCurveRight)

                        // Special
                        sectionHeader("Special")
                        pieceRow(.crossover)

                        // Info
                        infoSection()
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Banestykker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Luk") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            Spacer()
        }
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private func pieceRow(_ piece: TrackPiece) -> some View {
        HStack(spacing: 16) {
            // Ikon
            Image(systemName: piece.iconName)
                .font(.system(size: 24))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.15))
                )

            // Tekst
            VStack(alignment: .leading, spacing: 4) {
                Text(piece.displayName)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text(piece.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Vinkel badge
            if piece.angleDegrees != 0 {
                Text("\(Int(piece.angleDegrees))°")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(piece.angleDegrees > 0 ? .green : .blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
        .padding(.vertical, 2)
    }

    private func infoSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Regler for lukkede baner")

            infoItem(icon: "arrow.triangle.2.circlepath",
                     text: "Vinkelsum skal være 360° (eller 0° for otte-tal)")
            infoItem(icon: "rectangle.portrait.and.arrow.right",
                     text: "4 kurvesektioner = 180° sving")
            infoItem(icon: "equal.square",
                     text: "Modstående sider skal have samme længde")
            infoItem(icon: "arrow.left.arrow.right",
                     text: "Brede kurver på modstående hjørner")
        }
    }

    private func infoItem(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.yellow)
                .frame(width: 30)

            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.vertical, 4)
    }
}
