//
//  Advertising.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class Advertising: PageReservation {
    @Persisted(originProperty: "advertisements") var publication: LinkingObjects<Publication>
}
