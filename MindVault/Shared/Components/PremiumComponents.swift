import SwiftUI

struct AnimatedMeshBackground: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var animate = false

    var body: some View {
        LinearGradient(
            colors: [
                themeManager.isDarkAppearance
                    ? Color(red: 0.10, green: 0.14, blue: 0.18)
                    : Color(red: 0.84, green: 0.88, blue: 0.92),
                themeManager.isDarkAppearance
                    ? Color(red: 0.16, green: 0.22, blue: 0.20)
                    : Color(red: 0.88, green: 0.91, blue: 0.84),
                themeManager.isDarkAppearance
                    ? Color(red: 0.22, green: 0.20, blue: 0.18)
                    : Color(red: 0.95, green: 0.91, blue: 0.84)
            ],
            startPoint: animate ? .topLeading : .bottomTrailing,
            endPoint: animate ? .bottomTrailing : .topLeading
        )
        .overlay(themeManager.appBackgroundColor.opacity(themeManager.isDarkAppearance ? 0.48 : 0.22))
        .overlay(alignment: .topLeading) {
            Circle()
                .fill(Color.white.opacity(themeManager.isDarkAppearance ? 0.10 : 0.20))
                .frame(width: 240, height: 240)
                .blur(radius: 28)
                .offset(x: -40, y: -60)
        }
        .overlay(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 100)
                .fill(Color(red: 0.96, green: 0.84, blue: 0.62).opacity(themeManager.isDarkAppearance ? 0.12 : 0.24))
                .frame(width: 260, height: 260)
                .rotationEffect(.degrees(animate ? 16 : -12))
                .blur(radius: 30)
                .offset(x: 80, y: 80)
        }
        .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
        .onAppear { animate = true }
    }
}

struct PremiumCard<Content: View>: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(20)
            .background(themeManager.cardBackgroundColor, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(themeManager.cardBorderColor)
            }
            .shadow(color: themeManager.shadowColor, radius: 18, y: 10)
    }
}

struct SectionTitle: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let eyebrow: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow.uppercased())
                .font(themeManager.font(.caption, weight: .semibold))
                .tracking(1.6)
                .foregroundStyle(themeManager.secondaryTextColor)
            Text(title)
                .font(themeManager.font(.largeTitle, weight: .bold))
                .foregroundStyle(themeManager.primaryTextColor)
            Text(subtitle)
                .font(themeManager.font(.callout))
                .foregroundStyle(themeManager.secondaryTextColor)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
