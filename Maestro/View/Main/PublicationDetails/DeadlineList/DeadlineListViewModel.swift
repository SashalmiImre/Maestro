//
//  DeadlineListViewModel.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 29..
//

import Foundation
import SwiftUI
import RealmSwift

extension DeadlineListView {
    struct DeadlineListViewModel: DynamicProperty {
        @ObservedRealmObject var publication: Publication
        @State var isExpanded: Bool = true
        
        init(publication: ObservedRealmObject<Publication>) {
            self._publication = publication
        }
        
        func delete(deadline: Deadline) {
            guard let index = publication.deadlines.index(of: deadline) else { return }
            $publication.deadlines.remove(at: index)
        }
    }
}
