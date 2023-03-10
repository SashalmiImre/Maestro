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

private struct RealmApplication: EnvironmentKey {
    static let defaultValue: RealmSwift.App = RealmManager.shared.application
}

extension EnvironmentValues {
    var realmApplication: RealmSwift.App {
        RealmManager.shared.application
    }
}


// MARK: - XCode privew process info

extension EnvironmentValues {
    var isPreview: Bool {
        ProcessInfo.isPreview
    }
}
