//
//  MindVaultApp.swift
//  MindVault
//
//  Created by Ved Prakash Mishra on 05/04/26.
//

import SwiftUI

@main
struct MindVaultApp: App {
    @StateObject private var container = AppContainer.bootstrap()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(container)
                .environmentObject(container.session)
                .environmentObject(container.themeManager)
        }
    }
}
