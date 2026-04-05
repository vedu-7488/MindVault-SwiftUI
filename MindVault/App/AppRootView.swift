import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var container: AppContainer
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ZStack {
            AnimatedMeshBackground()
                .ignoresSafeArea()

            switch session.phase {
            case .launching:
                LaunchView()
            case .onboarding:
                OnboardingView(viewModel: OnboardingViewModel(session: session, securityManager: container.securityManager))
            case .locked:
                LockView(viewModel: LockViewModel(session: session, securityManager: container.securityManager))
            case .unlocked:
                MainTabView()
                    .environmentObject(session)
                    .environment(\.managedObjectContext, container.persistenceManager.viewContext)
                    .tint(container.themeManager.primaryTextColor)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .task {
            await session.launch()
        }
    }
}

private struct LaunchView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(themeManager.elevatedFillColor)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulse ? 1.08 : 0.92)
                Image(systemName: "book.pages.fill")
                    .font(themeManager.font(.largeTitle, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)
            }
            Text("MindVault")
                .font(themeManager.font(.largeTitle, weight: .bold))
                .foregroundStyle(themeManager.primaryTextColor)
            Text("Quiet space for thoughts, rituals, and reflection.")
                .font(themeManager.font(.callout))
                .foregroundStyle(themeManager.secondaryTextColor)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
