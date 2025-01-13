//
//  LayoutViewContext.swift
//  Maestro
//
//  Created by Sashalmi Imre on 12/01/2025.
//

import Foundation
import SwiftUI

class LayoutViewContext: ObservableObject {
    @Published var scrollViewAvaiableSize: CGSize = .zero
    @Published var scrollViewProxy: ScrollViewProxy?
    
}
