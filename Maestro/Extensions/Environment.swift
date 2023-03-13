//
//  Environment.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 27..
//

import Foundation
import RealmSwift
import SwiftUI


// MARK: - Realm application

private struct RealmApplicationEnvironmentKey: EnvironmentKey {
    static let defaultValue: RealmSwift.App = RealmManager.shared.application
}

extension EnvironmentValues {
    var realmApplication: RealmSwift.App {
        get { self[RealmApplicationEnvironmentKey.self] }
    }
}


//  MARK: - Realm manager

private struct RealmManagerEnvironmentKey: EnvironmentKey {
    static let defaultValue: RealmManager = .shared
}

extension EnvironmentValues {
    var realmManager: RealmManager {
        get { self[RealmManagerEnvironmentKey.self] }
    }
}
