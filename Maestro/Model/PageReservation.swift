//
//  PageReservation.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class PageReservation: EmbeddedObject {
    enum Mode: String, PersistableEnum {
        case exclusive
        case permissive
    }
    
    enum Orientation: String, PersistableEnum {
        case portrait
        case landscape
    }
    
    @Persisted var name: String = "Untitled"
    @Persisted var pageNumber: Int = 1
    @Persisted var percentage: Int = 100
    @Persisted var pageSize: Size? = Size()
    @Persisted var orientation: Orientation = .portrait
    @Persisted var mode: Mode = .exclusive
}


// MARK: - For preview

#if DEBUG
extension PageReservation {
    static var pageReservation1: PageReservation {
        let pageReservation = PageReservation()
        pageReservation.orientation = .portrait
        pageReservation.percentage = 100
        pageReservation.pageNumber = 3
        return pageReservation
    }
}
#endif
