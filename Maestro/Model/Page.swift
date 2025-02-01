//
//  Page.swift
//  Maestro
//
//  Created by Sashalmi Imre on 28/12/2024.
//

import PDFKit

class Page: Hashable {
    var pageNumber: Int
    unowned var article: Article?
    let pdfPage: PDFDocument?
    
    init(article: Article?, pageNumber: Int, pdfPage: PDFDocument?) {
        self.article = article
        self.pageNumber = pageNumber
        self.pdfPage = pdfPage
    }
    
    // MARK: - Hashable Implementation
    func hash(into hasher: inout Hasher) {
        hasher.combine(pageNumber)
        hasher.combine(article)
    }
    
    // MARK: - Equatable Implementation
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.pageNumber == rhs.pageNumber &&
               lhs.article == rhs.article
    }
}
