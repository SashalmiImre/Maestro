//
//  MaestroApp.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 13..
//

import SwiftUI
import RealmSwift
import BackgroundTasks

@main
struct MaestroApp: SwiftUI.App {
    private var realmManager: RealmManager = .shared
    
#if os(iOS)
    @Environment(\.scenePhase) private var phase
#endif

    var body: some Scene {
        WindowGroup {
            RealmView {
                LoginView()
            } content: {
                MainView()
            }
        }
#if os(iOS)
        .onChange(of: phase) { newPhase in
            switch newPhase {
            case .background: scheduleAppRefresh()
            default: break
            }
        }
        .backgroundTask(.appRefresh("refreshMaestro")) {
            guard let user = RealmManager.shared.application.currentUser else { return }
            await refreshSyncedRealm()
        }
#endif
    }
    
#if os(iOS)
    private func scheduleAppRefresh() {
        let backgroundTask = BGAppRefreshTaskRequest(identifier: "refreshMaestro")
        backgroundTask.earliestBeginDate = .now.addingTimeInterval(10)
        try? BGTaskScheduler.shared.submit(backgroundTask)
    }
    
    private func refreshSyncedRealm(config: Realm.Configuration = Realm.Configuration.defaultConfiguration) async {
      do {
        try await Realm(configuration: config, downloadBeforeOpen: .always)
      } catch {
        print("Error opening the Synced realm: \(error.localizedDescription)")
      }
    }
#endif
}
