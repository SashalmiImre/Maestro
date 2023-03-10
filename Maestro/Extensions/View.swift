//
//  View.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 16..
//

import Foundation
import SwiftUI

extension View {
    func hidden(_ hidden: Bool) -> some View {
        self.opacity(hidden ? 0 : 1)
    }
}
