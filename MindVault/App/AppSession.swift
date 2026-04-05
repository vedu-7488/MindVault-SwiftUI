import Combine
import CoreData
import Foundation

@MainActor
enum AppPhase {
    case launching
    case onboarding
    case locked
    case unlocked
}

@MainActor
final class AppSession: ObservableObject {
    @Published private(set) var phase: AppPhase = .launching
    @Published var selectedDate = Date()
    @Published var activeTab: AppTab = .journal
    @Published var isPerformingReset = false
    @Published var authErrorMessage: String?

    private let persistenceManager: PersistenceManaging
    private let storageManager: StorageManaging
    private let securityManager: SecurityManaging
    private let themeManager: ThemeManager
    private let notificationManager: NotificationManaging
    private let seedDataProvider: SeedDataProviding
    private let defaults: UserDefaults
    private var hasLaunched = false
    private let minimumLaunchDuration: Duration = .seconds(1.2)

    init(
        persistenceManager: PersistenceManaging,
        storageManager: StorageManaging,
        securityManager: SecurityManaging,
        themeManager: ThemeManager,
        notificationManager: NotificationManaging,
        seedDataProvider: SeedDataProviding,
        defaults: UserDefaults = .standard
    ) {
        self.persistenceManager = persistenceManager
        self.storageManager = storageManager
        self.securityManager = securityManager
        self.themeManager = themeManager
        self.notificationManager = notificationManager
        self.seedDataProvider = seedDataProvider
        self.defaults = defaults
    }

    func launch() async {
        guard !hasLaunched else { return }
        hasLaunched = true
        phase = .launching
        let launchStart = ContinuousClock.now
        themeManager.reload()
        let hasCompletedOnboarding = defaults.bool(forKey: AppStorageKey.hasCompletedOnboarding)
        let destinationPhase: AppPhase
        if !hasCompletedOnboarding {
            destinationPhase = .onboarding
        } else {
            destinationPhase = securityManager.hasConfiguredPasscode ? .locked : .onboarding
        }

        let elapsed = launchStart.duration(to: .now)
        if elapsed < minimumLaunchDuration {
            try? await Task.sleep(for: minimumLaunchDuration - elapsed)
        }
        phase = destinationPhase

        Task {
            await seedIfNeeded()
        }
    }

    func completeOnboarding() {
        defaults.set(true, forKey: AppStorageKey.hasCompletedOnboarding)
        phase = .locked
    }

    func configureSecurity(passcode: String, confirmation: String, useBiometrics: Bool) {
        guard passcode == confirmation else {
            authErrorMessage = SecurityError.mismatchedPasscode.localizedDescription
            return
        }

        do {
            try securityManager.configure(passcode: passcode, biometricsEnabled: useBiometrics)
            authErrorMessage = nil
            phase = .locked
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func unlock(passcode: String) async {
        do {
            try securityManager.validate(passcode: passcode)
            authErrorMessage = nil
            phase = .unlocked
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func unlockWithBiometrics() async {
        do {
            try await securityManager.authenticateWithBiometrics()
            authErrorMessage = nil
            phase = .unlocked
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func lock() {
        phase = .locked
    }

    func logout() async {
        guard !isPerformingReset else { return }
        isPerformingReset = true
        defer { isPerformingReset = false }

        do {
            try await storageManager.clearAllData()
            themeManager.reload()
            await seedIfNeeded()
            phase = .onboarding
            activeTab = .journal
            selectedDate = .now
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }

    func refreshReminders() async {
        await notificationManager.refreshReminder(using: themeManager.settings)
    }

    private func seedIfNeeded() async {
        do {
            try await seedDataProvider.seedIfNeeded()
            if persistenceManager.fetchEntryCount() == 0 {
                try seedDataProvider.forceSeed()
            }
        } catch {
            authErrorMessage = error.localizedDescription
        }
    }
}

enum AppTab: Hashable {
    case journal
    case search
    case calendar
    case analytics
    case settings
}

enum AppStorageKey {
    static let hasCompletedOnboarding = "hasCompletedOnboarding"
    static let hasSeededData = "hasSeededData"
    static let themeSettings = "themeSettings"
    static let passcodeHash = "passcodeHash"
    static let biometricsEnabled = "biometricsEnabled"
}
