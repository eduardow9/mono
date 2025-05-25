import SwiftUI
#if os(macOS)
import AppKit
public typealias UXColor = NSColor
#else
import UIKit
#endif

extension UXColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255
        let b = CGFloat(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// Extensão para facilitar o acesso às cores dos Assets
extension Color {
    // Uso das cores do Assets.xcassets
    static let monoAccent = Color("AccentColor")
    static let monoAccentSecondary = Color("AccentColor").opacity(0.6)
    static let monoBorder = Color("BorderColor")
    static let monoBackground = Color("EditorBackground")
    static let monoFrame = Color("FrameColor")
    static let monoRectangleSelection = Color("AccentColor")
    static let monoRectangleSelectionOff = Color("RectangleSelectionOff")
    static let monoSelection = Color("SelectionColor")
    static let monoSidebar = Color("SidebarColor")
    static let monoTextPrimary = Color("TextPrimary")
    static let monoTextSecondary = Color("TextSecondary")
    
    // Método auxiliar para obter cor adaptativa se necessário
    static func adaptiveColor(light: Color, dark: Color) -> Color {
#if os(macOS)
    return Color(UXColor(name: nil) { appearance in
        if appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua {
            return UXColor(dark)
        } else {
            return UXColor(light)
        }
    })
#else
    return light     // fallback on iOS
#endif
    }
}

// Mantendo AppFonts, AppSpacing, etc.
enum AppFonts {
    static let title = Font.system(size: 18, weight: .bold)
    static let caption = Font.system(size: 12, weight: .light)
}

enum AppSpacing {
    static let small: CGFloat = 4
    static let medium: CGFloat = 8
    static let large: CGFloat = 16
    static let extraLarge: CGFloat = 32
}

enum AppRadius {
    static let small: CGFloat = 4
    static let regular: CGFloat = 6
    static let large: CGFloat = 10
}

enum AppIcons {
    static let folder = "folder"
    static let folderPlus = "folder.badge.plus"
    static let expand = "chevron.right"
    static let collapse = "chevron.down"
    static let tag = "tag"
}

enum AppMetrics {
    static let sidebarMinWidth: CGFloat = 220
    static let sidebarMaxWidth: CGFloat = 320
    static let rowHeight: CGFloat = 28
}
