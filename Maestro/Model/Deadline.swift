//
//  Deadline.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class Deadline: EmbeddedObject {
    @Persisted var date: Date
    @Persisted var startPageNumber: Int = 1
    @Persisted var endPageNumber: Int = 1
}
