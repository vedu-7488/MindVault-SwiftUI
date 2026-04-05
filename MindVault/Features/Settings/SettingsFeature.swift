import Combine
import SwiftUI
import UserNotifications

protocol NotificationManaging {
    func refreshReminder(using settings: AppSettings) async
}

final class NotificationManager: NotificationManaging {
    func refreshReminder(using settings: AppSettings) async {
        let center = UNUserNotificationCenter.current()
        _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        center.removePendingNotificationRequests(withIdentifiers: ["daily-reflection"])

        guard settings.remindersEnabled else { return }

        var components = DateComponents()
        components.hour = settings.reminderHour
        components.minute = settings.reminderMinute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let content = UNMutableNotificationContent()
        content.title = "Reflection Time"
        content.body = "Open MindVault and leave yourself a thoughtful note."
        content.sound = .default

        let request = UNNotificationRequest(identifier: "daily-reflection", content: content, trigger: trigger)
        try? await center.add(request)
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var showingLogoutConfirmation = false

    private let session: AppSession
    let themeManager: ThemeManager

    init(session: AppSession, themeManager: ThemeManager) {
        self.session = session
        self.themeManager = themeManager
    }

    func applyTheme(_ mode: ThemeMode) {
        themeManager.update { $0.themeMode = mode }
    }

    func applyFontScale(_ scale: Double) {
        themeManager.update { $0.fontScale = scale }
    }

    func applyFontStyle(_ style: AppFontStyle) {
        themeManager.update { $0.fontStyle = style }
    }

    func applyPalette(_ palette: AppTextPalette) {
        themeManager.update { $0.textPalette = palette }
    }

    func applyReminderToggle(_ enabled: Bool) {
        themeManager.update { $0.remindersEnabled = enabled }
        Task { await session.refreshReminders() }
    }

    func applyReminderTime(_ date: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        themeManager.update {
            $0.reminderHour = components.hour ?? 20
            $0.reminderMinute = components.minute ?? 30
        }
        Task { await session.refreshReminders() }
    }

    func logout() {
        Task { await session.logout() }
    }
}

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PremiumCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Appearance")
                            .font(viewModel.themeManager.font(.title3, weight: .bold))
                            .foregroundStyle(viewModel.themeManager.primaryTextColor)
                        Picker("Theme", selection: Binding(
                            get: { viewModel.themeManager.settings.themeMode },
                            set: viewModel.applyTheme
                        )) {
                            ForEach(ThemeMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Font Size")
                                .font(viewModel.themeManager.font(.headline, weight: .semibold))
                                .foregroundStyle(viewModel.themeManager.primaryTextColor)
                            Slider(
                                value: Binding(
                                    get: { viewModel.themeManager.settings.fontScale },
                                    set: viewModel.applyFontScale
                                ),
                                in: 0.85...1.3
                            )
                        }

                        Picker("Font Style", selection: Binding(
                            get: { viewModel.themeManager.settings.fontStyle },
                            set: viewModel.applyFontStyle
                        )) {
                            ForEach(AppFontStyle.allCases) { style in
                                Text(style.title).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)

                        HStack(spacing: 12) {
                            ForEach(AppTextPalette.allCases) { palette in
                                Button {
                                    viewModel.applyPalette(palette)
                                } label: {
                                    Circle()
                                        .fill(palette.color)
                                        .frame(width: 34, height: 34)
                                        .overlay {
                                            if viewModel.themeManager.settings.textPalette == palette {
                                                Circle().strokeBorder(.white, lineWidth: 2)
                                            }
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                PremiumCard {
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Reminders")
                            .font(viewModel.themeManager.font(.title3, weight: .bold))
                            .foregroundStyle(viewModel.themeManager.primaryTextColor)

                        Toggle("Daily reflection reminder", isOn: Binding(
                            get: { viewModel.themeManager.settings.remindersEnabled },
                            set: viewModel.applyReminderToggle
                        ))

                        DatePicker(
                            "Reminder Time",
                            selection: Binding(
                                get: {
                                    Calendar.current.date(
                                        bySettingHour: viewModel.themeManager.settings.reminderHour,
                                        minute: viewModel.themeManager.settings.reminderMinute,
                                        second: 0,
                                        of: .now
                                    ) ?? .now
                                },
                                set: viewModel.applyReminderTime
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                }

                Button(role: .destructive) {
                    viewModel.showingLogoutConfirmation = true
                } label: {
                    PremiumCard {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Logout and Clear All Data")
                                .font(viewModel.themeManager.font(.headline, weight: .semibold))
                            Spacer()
                        }
                        .foregroundStyle(.red)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .navigationTitle("Settings")
        .font(viewModel.themeManager.font(.body))
        .foregroundStyle(viewModel.themeManager.primaryTextColor)
        .background(backgroundLayer)
        .confirmationDialog("Clear all data and return to onboarding?", isPresented: $viewModel.showingLogoutConfirmation) {
            Button("Logout", role: .destructive) {
                viewModel.logout()
            }
        }
    }

    private var backgroundLayer: some View {
        viewModel.themeManager.appBackgroundColor
            .opacity(0.22)
            .ignoresSafeArea()
    }
}
