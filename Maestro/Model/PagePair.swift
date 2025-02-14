//
//  PagePair.swift
//  Maestro
//
//  Created by Sashalmi Imre on 30/12/2024.
//

import Foundation
import PDFKit

actor PagePair {
    unowned let leftArticle:  Article?
    unowned let rightArticle: Article?
    
    nonisolated var leftPage:  Page { leftArticle?[coverage.lowerBound]  ?? Page(pageNumber: coverage.lowerBound) }
    nonisolated var rightPage: Page { rightArticle?[coverage.upperBound] ?? Page(pageNumber: coverage.upperBound) }

    let coverage: ClosedRange<Int>

    init(coverage: ClosedRange<Int>, leftArticle: Article?, rightArticle: Article?) {
        self.coverage     = coverage
        self.leftArticle  = leftArticle
        self.rightArticle = rightArticle
    }
    
    subscript(pageNumber: Int) -> Page? {
        guard coverage.contains(pageNumber) else { return nil }
        return pageNumber == coverage.lowerBound ? leftPage : rightPage
    }
}
