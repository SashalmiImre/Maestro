//
//  Array.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 02..
//

import Foundation

extension Array {
    var lastElement: Element {
        get { self[self.endIndex - 1] }
        set { self[self.endIndex - 1] = newValue }
    }
}
