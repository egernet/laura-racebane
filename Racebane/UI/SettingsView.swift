import SwiftUI

/// Indstillinger
struct SettingsView: View {
    @AppStorage("hapticEnabled") private var hapticEnabled = true
    @AppStorage("difficulty") private var difficulty = 1 // 0=let, 1=normal, 2=svær
    @AppStorage("totalLaps") private var totalLaps = 3
    @AppStorage("selectedCarId") private var selectedCarId = 0
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
                    VStack(spacing: 24) {
                        // Bil-vælger
                        settingSection("Din bil") {
                            LazyVGrid(columns: [
                                GridItem(.flexible()), GridItem(.flexible()),
                                GridItem(.flexible()), GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(CarConfig.allCars) { car in
                                    Button {
                                        selectedCarId = car.id
                                    } label: {
                                        VStack(spacing: 4) {
                                            Circle()
                                                .fill(Color(uiColor: car.color))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Circle().stroke(Color.white, lineWidth: selectedCarId == car.id ? 3 : 0)
                                                )
                                            Text(car.colorName)
                                                .font(.system(size: 11, design: .rounded))
                                                .foregroundColor(.white.opacity(0.7))
                                        }
                                    }
                                }
                            }

                            if let car = CarConfig.allCars.first(where: { $0.id == selectedCarId }) {
                                Text(car.name)
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(uiColor: car.color))
                                    .padding(.top, 4)
                            }
                        }

                        // Sværhedsgrad
                        settingSection("Sværhedsgrad") {
                            Picker("Sværhedsgrad", selection: $difficulty) {
                                Text("Let").tag(0)
                                Text("Normal").tag(1)
                                Text("Svær").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Omgange
                        settingSection("Antal omgange") {
                            Picker("Omgange", selection: $totalLaps) {
                                Text("1").tag(1)
                                Text("3").tag(3)
                                Text("5").tag(5)
                                Text("10").tag(10)
                            }
                            .pickerStyle(.segmented)
                        }

                        // Haptic
                        settingSection("Vibration") {
                            Toggle("Haptic feedback", isOn: $hapticEnabled)
                                .tint(.green)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Indstillinger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Luk") { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: hapticEnabled) { newValue in
                HapticManager.shared.isEnabled = newValue
            }
        }
    }

    private func settingSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.orange)
            content()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white.opacity(0.08)))
    }
}
