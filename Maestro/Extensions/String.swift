//
//  String.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 03. 18..
//

import Foundation

extension String {
    func isStartingWithVowel() -> Bool {
        return "aáeéiíoóöőuúüű15_".contains { Character(self.first?.lowercased() ?? "") == $0}
    }
}
