import CryptoKit
import Foundation
import LocalAuthentication

protocol SecurityManaging {
    var isBiometricsAvailable: Bool { get }
    var isBiometricsEnabled: Bool { get }
    var hasConfiguredPasscode: Bool { get }
    func configure(passcode: String, biometricsEnabled: Bool) throws
    func authenticateWithBiometrics() async throws
    func validate(passcode: String) throws
    func clearCredentials()
}

enum SecurityError: LocalizedError {
    case unavailable
    case failed
    case invalidPasscode
    case passcodeNotConfigured
    case weakPasscode
    case mismatchedPasscode

    var errorDescription: String? {
        switch self {
        case .unavailable:
            return "Biometrics are not available on this device right now."
        case .failed:
            return "MindVault stayed locked. Try Face ID, Touch ID, or your app passcode again."
        case .invalidPasscode:
            return "That passcode doesn’t match your MindVault passcode."
        case .passcodeNotConfigured:
            return "Create a passcode before trying to unlock MindVault."
        case .weakPasscode:
            return "Use a 4-digit passcode to protect MindVault."
        case .mismatchedPasscode:
            return "Those passcodes didn’t match. Try again."
        }
    }
}

final class SecurityManager: SecurityManaging {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isBiometricsAvailable: Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }

    var isBiometricsEnabled: Bool {
        defaults.bool(forKey: AppStorageKey.biometricsEnabled)
    }

    var hasConfiguredPasscode: Bool {
        defaults.string(forKey: AppStorageKey.passcodeHash) != nil
    }

    func configure(passcode: String, biometricsEnabled: Bool) throws {
        guard passcode.count == 4, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: passcode)) else {
            throw SecurityError.weakPasscode
        }

        defaults.set(hash(passcode), forKey: AppStorageKey.passcodeHash)
        defaults.set(biometricsEnabled && isBiometricsAvailable, forKey: AppStorageKey.biometricsEnabled)
    }

    func authenticateWithBiometrics() async throws {
        guard isBiometricsEnabled else {
            throw SecurityError.unavailable
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw SecurityError.unavailable
        }

        let reason = "Unlock your private journal."
        do {
            try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch {
            throw SecurityError.failed
        }
    }

    func validate(passcode: String) throws {
        guard let storedHash = defaults.string(forKey: AppStorageKey.passcodeHash) else {
            throw SecurityError.passcodeNotConfigured
        }

        guard hash(passcode) == storedHash else {
            throw SecurityError.invalidPasscode
        }
    }

    func clearCredentials() {
        defaults.removeObject(forKey: AppStorageKey.passcodeHash)
        defaults.removeObject(forKey: AppStorageKey.biometricsEnabled)
    }

    private func hash(_ passcode: String) -> String {
        let digest = SHA256.hash(data: Data(passcode.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
