//
//  PagePair.swift
//  Maestro
//
//  Created by Sashalmi Imre on 30/12/2024.
//

import Foundation
import PDFKit

class PagePair: Hashable {
    let leftPage: Page
    let rightPage: Page

    var coverage: ClosedRange<Int> {
        return leftPage.pageNumber...rightPage.pageNumber
    }

    init(leftPage: Page, rightPage: Page) {
        self.leftPage  = leftPage
        self.rightPage = rightPage
    }
    
    static func == (lhs: PagePair, rhs: PagePair) -> Bool {
        return lhs.leftPage == rhs.leftPage
        && lhs.rightPage == rhs.rightPage
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(leftPage)
        hasher.combine(rightPage)
    }
}
