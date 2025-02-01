//
//  PagePair.swift
//  Maestro
//
//  Created by Sashalmi Imre on 30/12/2024.
//

import Foundation
import PDFKit

actor PagePair: Hashable {
    let leftPage: Page
    let rightPage: Page

    nonisolated var coverage: ClosedRange<Int> {
        return leftPage.pageNumber...rightPage.pageNumber
    }

    init(leftPage: Page, rightPage: Page) {
        self.leftPage  = leftPage
        self.rightPage = rightPage
    }
    
    
    // MARK: - Equatable Implementation

    static func == (lhs: PagePair, rhs: PagePair) -> Bool {
        return lhs.leftPage == rhs.leftPage
        && lhs.rightPage == rhs.rightPage
    }
   
    
    // MARK: - Hashable Implementation
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(leftPage)
        hasher.combine(rightPage)
    }
}
