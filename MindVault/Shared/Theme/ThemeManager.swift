import Combine
import SwiftUI
import UIKit

enum ThemeMode: String, CaseIterable, Codable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum AppFontStyle: String, CaseIterable, Codable, Identifiable {
    case rounded
    case serif
    case defaultStyle

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rounded: return "Rounded"
        case .serif: return "Serif"
        case .defaultStyle: return "System"
        }
    }

    var design: Font.Design {
        switch self {
        case .rounded: return .rounded
        case .serif: return .serif
        case .defaultStyle: return .default
        }
    }
}

enum AppTextPalette: String, CaseIterable, Codable, Identifiable {
    case graphite
    case forest
    case navy
    case cocoa

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var color: Color {
        Color(uiColor)
    }

    var uiColor: UIColor {
        switch self {
        case .graphite: return UIColor(red: 0.15, green: 0.16, blue: 0.18, alpha: 1)
        case .forest: return UIColor(red: 0.12, green: 0.28, blue: 0.24, alpha: 1)
        case .navy: return UIColor(red: 0.13, green: 0.18, blue: 0.35, alpha: 1)
        case .cocoa: return UIColor(red: 0.33, green: 0.22, blue: 0.18, alpha: 1)
        }
    }
}

struct AppSettings: Codable, Equatable {
    var themeMode: ThemeMode = .system
    var fontScale: Double = 1.0
    var fontStyle: AppFontStyle = .rounded
    var textPalette: AppTextPalette = .graphite
    var remindersEnabled = true
    var reminderHour = 20
    var reminderMinute = 30
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published private(set) var settings: AppSettings

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if
            let data = defaults.data(forKey: AppStorageKey.themeSettings),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    var colorScheme: ColorScheme? {
        switch settings.themeMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    var isDarkAppearance: Bool {
        settings.themeMode == .dark
    }

    var primaryTextColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0) ? UIColor(white: 0.96, alpha: 1) : self.settings.textPalette.uiColor
        })
    }

    var secondaryTextColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(white: 1.0, alpha: 0.72)
                : self.settings.textPalette.uiColor.withAlphaComponent(0.72)
        })
    }

    var appBackgroundColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(red: 0.06, green: 0.08, blue: 0.10, alpha: 1)
                : UIColor(red: 0.97, green: 0.95, blue: 0.91, alpha: 1)
        })
    }

    var cardBackgroundColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(white: 1.0, alpha: 0.08)
                : UIColor(white: 1.0, alpha: 0.72)
        })
    }

    var cardBorderColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(white: 1.0, alpha: 0.12)
                : self.settings.textPalette.uiColor.withAlphaComponent(0.10)
        })
    }

    var elevatedFillColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(white: 1.0, alpha: 0.12)
                : UIColor(white: 1.0, alpha: 0.82)
        })
    }

    var shadowColor: Color {
        Color(dynamicColor {
            self.resolvedDark(for: $0)
                ? UIColor(white: 0.0, alpha: 0.28)
                : UIColor(white: 0.0, alpha: 0.10)
        })
    }

    func font(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(size: pointSize(for: style) * settings.fontScale, weight: weight, design: settings.fontStyle.design)
    }

    func scaled(_ value: CGFloat) -> CGFloat {
        value * settings.fontScale
    }

    func update(_ mutate: (inout AppSettings) -> Void) {
        var newSettings = settings
        mutate(&newSettings)
        settings = newSettings
        persist()
    }

    func reload() {
        if
            let data = defaults.data(forKey: AppStorageKey.themeSettings),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: AppStorageKey.themeSettings)
        }
    }

    private func dynamicColor(_ provider: @escaping (UIUserInterfaceStyle) -> UIColor) -> UIColor {
        UIColor { traits in
            provider(traits.userInterfaceStyle)
        }
    }

    private func resolvedDark(for interfaceStyle: UIUserInterfaceStyle) -> Bool {
        switch settings.themeMode {
        case .dark:
            return true
        case .light:
            return false
        case .system:
            return interfaceStyle == .dark
        }
    }

    private func pointSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle: return 34
        case .title: return 28
        case .title2: return 22
        case .title3: return 20
        case .headline: return 17
        case .subheadline: return 15
        case .callout: return 16
        case .caption: return 12
        case .caption2: return 11
        case .footnote: return 13
        default: return 17
        }
    }
}
