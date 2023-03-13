//
//  RealmViewModel.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 15..
//

import Foundation
import SwiftUI
import RealmSwift
import Combine

extension RealmView {
    struct RealmViewModel: DynamicProperty {
        @AutoOpen(appId: RealmManager.appId, timeout: 4000) var autoOpen
        var subscriptions: Set<AnyCancellable> = .init()
        @State var realmErrorMessage: String?
    }
}
