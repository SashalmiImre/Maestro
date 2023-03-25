//
//  DeadlineProjection.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 25..
//

import Foundation
import RealmSwift

class DeadlineProjection: Projection<Deadline> {
    @Projected(\Deadline.date) var date
    @Projected(\Deadline.startPageNumber) var startPageNumber
    @Projected(\Deadline.endPageNumber) var endPageNumber
}
