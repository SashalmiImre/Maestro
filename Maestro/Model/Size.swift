//
//  Size.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 16..
//

import Foundation
import RealmSwift

class Size: EmbeddedObject {
    @Persisted var width: Int = 205
    @Persisted var height: Int = 275
}
