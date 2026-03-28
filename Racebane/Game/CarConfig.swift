import UIKit

/// Bilkonfiguration: navn, farve
struct CarConfig: Identifiable, Equatable {
    let id: Int
    let name: String
    let color: UIColor
    let colorName: String

    static let allCars: [CarConfig] = [
        CarConfig(id: 0, name: "Pink Raket", color: .systemPink, colorName: "Pink"),
        CarConfig(id: 1, name: "Lyn-Laura", color: .systemPurple, colorName: "Lilla"),
        CarConfig(id: 2, name: "Turbo Star", color: .systemCyan, colorName: "Turkis"),
        CarConfig(id: 3, name: "Orange Ild", color: .systemOrange, colorName: "Orange"),
        CarConfig(id: 4, name: "Grøn Pil", color: .systemGreen, colorName: "Grøn"),
        CarConfig(id: 5, name: "Rød Torden", color: .systemRed, colorName: "Rød"),
        CarConfig(id: 6, name: "Blå Bølge", color: .systemBlue, colorName: "Blå"),
        CarConfig(id: 7, name: "Gul Lynild", color: .systemYellow, colorName: "Gul"),
    ]
}
