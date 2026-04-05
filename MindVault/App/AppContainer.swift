import Combine
import SwiftUI

@MainActor
final class AppContainer: ObservableObject {
    let persistenceManager: PersistenceManaging
    let storageManager: StorageManaging
    let securityManager: SecurityManaging
    let themeManager: ThemeManager
    let notificationManager: NotificationManaging
    let calendarManager: CalendarManaging
    let seedDataProvider: SeedDataProviding
    let session: AppSession

    init(
        persistenceManager: PersistenceManaging,
        storageManager: StorageManaging,
        securityManager: SecurityManaging,
        themeManager: ThemeManager,
        notificationManager: NotificationManaging,
        calendarManager: CalendarManaging,
        seedDataProvider: SeedDataProviding,
        session: AppSession
    ) {
        self.persistenceManager = persistenceManager
        self.storageManager = storageManager
        self.securityManager = securityManager
        self.themeManager = themeManager
        self.notificationManager = notificationManager
        self.calendarManager = calendarManager
        self.seedDataProvider = seedDataProvider
        self.session = session
    }

    static func bootstrap() -> AppContainer {
        let persistenceManager = PersistenceManager()
        let themeManager = ThemeManager()
        let notificationManager = NotificationManager()
        let calendarManager = CalendarManager()
        let securityManager = SecurityManager()
        let storageManager = StorageManager(persistenceManager: persistenceManager)
        let seedDataProvider = SeedDataProvider(persistenceManager: persistenceManager)
        let session = AppSession(
            persistenceManager: persistenceManager,
            storageManager: storageManager,
            securityManager: securityManager,
            themeManager: themeManager,
            notificationManager: notificationManager,
            seedDataProvider: seedDataProvider
        )

        return AppContainer(
            persistenceManager: persistenceManager,
            storageManager: storageManager,
            securityManager: securityManager,
            themeManager: themeManager,
            notificationManager: notificationManager,
            calendarManager: calendarManager,
            seedDataProvider: seedDataProvider,
            session: session
        )
    }
}
