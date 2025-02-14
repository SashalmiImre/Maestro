//
//  LayoutViewContext.swift
//  Maestro
//
//  Created by Sashalmi Imre on 12/01/2025.
//

import Foundation
import SwiftUI

class LayoutViewContext: ObservableObject, FocusedValueKey {
    typealias Value = LayoutViewContext
    
    @Published var scrollViewAvaiableSize: CGSize = .zero
    @Published var scrollViewContentSize: CGSize = .zero
 
    var scrollViewProxy: ScrollViewProxy?
}
