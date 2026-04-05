import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var selectedMood = "Calm"
    @Published var expandedCard = false
    @Published var passcode = ""
    @Published var confirmation = ""
    @Published var useBiometrics = true
    @Published var localErrorMessage: String?

    private let session: AppSession
    private let securityManager: SecurityManaging

    let moods = ["Calm", "Focused", "Happy", "Reflective"]
    let totalPages = 5

    init(session: AppSession, securityManager: SecurityManaging) {
        self.session = session
        self.securityManager = securityManager
        self.useBiometrics = securityManager.isBiometricsAvailable
    }

    var isLastPage: Bool {
        currentPage == totalPages - 1
    }

    var canGoBack: Bool {
        currentPage > 0
    }

    var showsSkip: Bool {
        !isLastPage
    }

    var biometricsAvailable: Bool {
        securityManager.isBiometricsAvailable
    }

    var primaryActionTitle: String {
        isLastPage ? "Finish Setup" : "Continue"
    }

    var canSubmitSecurity: Bool {
        passcode.count == 4 && confirmation.count == 4
    }

    func next() {
        localErrorMessage = nil
        if isLastPage {
            finish()
        } else {
            withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.86)) {
                currentPage += 1
            }
        }
    }

    func back() {
        guard canGoBack else { return }
        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.86)) {
            currentPage -= 1
        }
    }

    func skipToEnd() {
        withAnimation(.interactiveSpring(response: 0.42, dampingFraction: 0.86)) {
            currentPage = totalPages - 1
        }
    }

    func finish() {
        guard passcode == confirmation else {
            localErrorMessage = SecurityError.mismatchedPasscode.localizedDescription
            return
        }

        session.configureSecurity(
            passcode: passcode,
            confirmation: confirmation,
            useBiometrics: useBiometrics
        )

        if session.authErrorMessage == nil {
            session.completeOnboarding()
        }
    }

    var securityHint: String {
        if securityManager.isBiometricsAvailable {
            return "Create a 4-digit MindVault passcode and optionally enable Face ID or Touch ID for quick unlock."
        } else {
            return "Create a 4-digit MindVault passcode to protect your private journal on this device."
        }
    }
}

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager
    @Namespace private var namespace

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                Spacer(minLength: 12)

                TabView(selection: $viewModel.currentPage) {
                    welcomePage.tag(0)
                    capturePage.tag(1)
                    moodPage.tag(2)
                    securityPage.tag(3)
                    passcodeSetupPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: max(420, proxy.size.height - 210))

                VStack(spacing: 18) {
                    CapsuleProgressIndicator(total: viewModel.totalPages, current: viewModel.currentPage)
                        .padding(.top, 8)

                    HStack(spacing: 12) {
                        Button(action: viewModel.back) {
                            Text("Back")
                                .font(themeManager.font(.headline, weight: .semibold))
                                .foregroundStyle(themeManager.primaryTextColor.opacity(viewModel.canGoBack ? 1 : 0.45))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(themeManager.elevatedFillColor.opacity(viewModel.canGoBack ? 1 : 0.72), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .disabled(!viewModel.canGoBack)

                        Button(action: viewModel.next) {
                            Text(viewModel.primaryActionTitle)
                                .font(themeManager.font(.headline, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color(red: 0.97, green: 0.92, blue: 0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }

                    if let message = viewModel.localErrorMessage ?? sessionError {
                        Text(message)
                            .font(themeManager.font(.callout))
                            .foregroundStyle(themeManager.primaryTextColor.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }

                    if viewModel.showsSkip {
                        Button("Skip") {
                            viewModel.skipToEnd()
                        }
                        .font(themeManager.font(.subheadline, weight: .semibold))
                        .foregroundStyle(themeManager.secondaryTextColor)
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, max(18, proxy.safeAreaInsets.bottom))
                .background(themeManager.cardBackgroundColor.opacity(0.96))
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private var sessionError: String? { session.authErrorMessage }

    private var welcomePage: some View {
        VStack(spacing: 22) {
            SectionTitle(
                eyebrow: "Welcome",
                title: "A softer place to think.",
                subtitle: "MindVault is built for calm reflection, fast capture, and private moments that stay yours."
            )
            PremiumCard {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    themeManager.elevatedFillColor.opacity(0.95),
                                    themeManager.cardBackgroundColor.opacity(0.85)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Today")
                            .font(themeManager.font(.caption, weight: .semibold))
                            .foregroundStyle(themeManager.secondaryTextColor)
                        Text("Your thoughts deserve more than a blank text box.")
                            .font(themeManager.font(.title2, weight: .bold))
                            .foregroundStyle(themeManager.primaryTextColor)
                        HStack(spacing: 12) {
                            miniPill("Private")
                            miniPill("Offline")
                            miniPill("Instant")
                        }
                    }
                    .padding(24)
                }
                .frame(height: 260)
            }
        }
        .padding(.horizontal)
    }

    private var capturePage: some View {
        VStack(spacing: 22) {
            SectionTitle(
                eyebrow: "Capture Thoughts",
                title: "Tap into the moment.",
                subtitle: "Preview the editor experience with a live journal card that expands when curiosity kicks in."
            )
            Button {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    viewModel.expandedCard.toggle()
                }
            } label: {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Morning Reset")
                                .font(themeManager.font(.title3, weight: .bold))
                                .foregroundStyle(themeManager.primaryTextColor)
                                .matchedGeometryEffect(id: "cardTitle", in: namespace)
                            Spacer()
                            Image(systemName: viewModel.expandedCard ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                                .foregroundStyle(themeManager.secondaryTextColor)
                        }
                        Text(viewModel.expandedCard ? "Started gently today. I noticed that even a five minute pause changed the pace of the whole morning. I want more of that spacious feeling this week." : "Started gently today. Even a five minute pause changed the pace.")
                            .font(themeManager.font(.body))
                            .foregroundStyle(themeManager.secondaryTextColor)
                            .lineLimit(viewModel.expandedCard ? 5 : 2)
                        HStack {
                            miniPill("Reflective")
                            miniPill("Tap to expand")
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: viewModel.expandedCard ? 280 : 200, alignment: .topLeading)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
    }

    private var moodPage: some View {
        VStack(spacing: 22) {
            SectionTitle(
                eyebrow: "Mood Tracking",
                title: "Let emotion be visible.",
                subtitle: "A quick emotional check-in brings useful context to every entry without adding friction."
            )
            PremiumCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("How are you arriving today?")
                        .font(themeManager.font(.headline, weight: .semibold))
                        .foregroundStyle(themeManager.primaryTextColor)
                    HStack(spacing: 12) {
                        ForEach(viewModel.moods, id: \.self) { mood in
                            Button {
                                withAnimation(.interactiveSpring(response: 0.35, dampingFraction: 0.75)) {
                                    viewModel.selectedMood = mood
                                }
                            } label: {
                                VStack(spacing: 8) {
                                    Text(icon(for: mood))
                                        .font(themeManager.font(.title))
                                    Text(mood)
                                        .font(themeManager.font(.caption, weight: .medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(viewModel.selectedMood == mood ? Color(red: 0.97, green: 0.92, blue: 0.82) : themeManager.elevatedFillColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .scaleEffect(viewModel.selectedMood == mood ? 1.06 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(viewModel.selectedMood == mood ? Color.black : themeManager.primaryTextColor)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var securityPage: some View {
        VStack(spacing: 22) {
            SectionTitle(
                eyebrow: "Security",
                title: "Protected by your device.",
                subtitle: "MindVault uses a private app passcode, with optional biometrics for quick unlock. No signup, no cloud account, no external server."
            )
            PremiumCard {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(themeManager.elevatedFillColor, lineWidth: 18)
                            .frame(width: 160, height: 160)
                        Circle()
                            .trim(from: 0.0, to: 0.72)
                            .stroke(Color(red: 0.97, green: 0.92, blue: 0.82), style: StrokeStyle(lineWidth: 18, lineCap: .round))
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                        Image(systemName: "faceid")
                            .font(themeManager.font(.largeTitle, weight: .medium))
                            .foregroundStyle(themeManager.primaryTextColor)
                    }
                    Text("Everything stays on device unless you choose otherwise later.")
                        .font(themeManager.font(.headline, weight: .semibold))
                        .foregroundStyle(themeManager.primaryTextColor)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal)
    }

    private var passcodeSetupPage: some View {
        VStack(spacing: 22) {
            SectionTitle(
                eyebrow: "Final Step",
                title: "Create your MindVault passcode.",
                subtitle: viewModel.securityHint
            )
            PremiumCard {
                VStack(alignment: .leading, spacing: 18) {
                    Text("This is the passcode you’ll use to unlock the app later.")
                        .font(themeManager.font(.headline, weight: .semibold))
                        .foregroundStyle(themeManager.primaryTextColor)

                    SecureField("4-digit passcode", text: $viewModel.passcode)
                        .font(themeManager.font(.body))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(themeManager.elevatedFillColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    SecureField("Confirm passcode", text: $viewModel.confirmation)
                        .font(themeManager.font(.body))
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .padding()
                        .background(themeManager.elevatedFillColor, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                    if viewModel.biometricsAvailable {
                        Toggle("Enable Face ID / Touch ID", isOn: $viewModel.useBiometrics)
                            .font(themeManager.font(.body))
                            .foregroundStyle(themeManager.primaryTextColor)
                            .tint(Color(red: 0.97, green: 0.92, blue: 0.82))
                    }

                    Text("If you ever forget this passcode, the recovery path is a full local reset that clears journal data on this device.")
                        .font(themeManager.font(.callout))
                        .foregroundStyle(themeManager.secondaryTextColor)
                }
            }
        }
        .padding(.horizontal)
    }

    private func miniPill(_ title: String) -> some View {
        Text(title)
            .font(themeManager.font(.caption, weight: .semibold))
            .foregroundStyle(themeManager.primaryTextColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.elevatedFillColor, in: Capsule())
    }

    private func icon(for mood: String) -> String {
        switch mood {
        case "Calm": return "😌"
        case "Focused": return "🧠"
        case "Happy": return "🙂"
        default: return "🌙"
        }
    }
}

private struct CapsuleProgressIndicator: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index == current ? .white : .white.opacity(0.24))
                    .frame(width: index == current ? 36 : 10, height: 10)
                    .animation(.easeInOut(duration: 0.28), value: current)
            }
        }
    }
}

final class LockViewModel: ObservableObject {
    @Published var isAuthenticating = false
    @Published var passcode = ""

    private let session: AppSession
    let securityManager: SecurityManaging

    init(session: AppSession, securityManager: SecurityManaging) {
        self.session = session
        self.securityManager = securityManager
    }

    func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        Task {
            await session.unlock(passcode: passcode)
            isAuthenticating = false
        }
    }

    func unlockWithBiometrics() {
        guard !isAuthenticating, securityManager.isBiometricsEnabled else { return }
        isAuthenticating = true
        Task {
            await session.unlockWithBiometrics()
            isAuthenticating = false
        }
    }
}

struct LockView: View {
    @StateObject var viewModel: LockViewModel
    @EnvironmentObject private var session: AppSession
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showResetConfirmation = false

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            ZStack {
                Circle()
                    .fill(themeManager.elevatedFillColor)
                    .frame(width: 168, height: 168)
                Image(systemName: "lock.shield.fill")
                    .font(themeManager.font(.largeTitle, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)
            }
            Text("Private by default")
                .font(themeManager.font(.largeTitle, weight: .bold))
                .foregroundStyle(themeManager.primaryTextColor)
            Text("Unlock with your MindVault passcode, or use biometrics if you enabled them.")
                .font(themeManager.font(.body))
                .multilineTextAlignment(.center)
                .foregroundStyle(themeManager.secondaryTextColor)
                .padding(.horizontal, 32)

            SecureField("MindVault passcode", text: $viewModel.passcode)
                .font(themeManager.font(.body))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(themeManager.elevatedFillColor, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 28)

            if let message = session.authErrorMessage {
                Text(message)
                    .font(themeManager.font(.callout))
                    .foregroundStyle(themeManager.primaryTextColor.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button(action: viewModel.unlock) {
                HStack(spacing: 10) {
                    Image(systemName: "lock.open.fill")
                    Text(viewModel.isAuthenticating ? "Unlocking..." : "Unlock")
                }
                .font(themeManager.font(.headline, weight: .semibold))
                .foregroundStyle(.black)
                .padding(.horizontal, 28)
                .padding(.vertical, 16)
                .background(Color(red: 0.97, green: 0.92, blue: 0.82), in: Capsule())
            }
            .buttonStyle(.plain)

            if viewModel.securityManager.isBiometricsEnabled {
                Button(action: viewModel.unlockWithBiometrics) {
                    HStack(spacing: 10) {
                        Image(systemName: "faceid")
                        Text("Use Biometrics")
                    }
                    .font(themeManager.font(.headline, weight: .semibold))
                    .foregroundStyle(themeManager.primaryTextColor)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(themeManager.elevatedFillColor, in: Capsule())
                }
                .buttonStyle(.plain)
            }

            Text("Forgot passcode?")
                .font(themeManager.font(.headline, weight: .semibold))
                .foregroundStyle(themeManager.primaryTextColor)
            Text("MindVault does not use signup or cloud recovery. Resetting will erase local journal data and return you to onboarding.")
                .font(themeManager.font(.callout))
                .multilineTextAlignment(.center)
                .foregroundStyle(themeManager.secondaryTextColor)
                .padding(.horizontal, 28)

            Button("Reset MindVault") {
                showResetConfirmation = true
            }
            .font(themeManager.font(.subheadline, weight: .semibold))
            .foregroundStyle(themeManager.primaryTextColor.opacity(0.88))
            .buttonStyle(.plain)
            Spacer()
        }
        .confirmationDialog("Reset MindVault and erase all local data?", isPresented: $showResetConfirmation) {
            Button("Reset MindVault", role: .destructive) {
                Task { await session.logout() }
            }
        }
    }
}
