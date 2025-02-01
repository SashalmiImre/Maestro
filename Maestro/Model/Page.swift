//
//  Page.swift
//  Maestro
//
//  Created by Sashalmi Imre on 28/12/2024.
//

import PDFKit

actor Page: Hashable {
    
    unowned let article: Article?
    let pageNumber: Int
    let pdfData: Data?
    
    nonisolated(unsafe) var pdfPage: PDFPage? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)?.page(at: 0)
    }
    
    init(article: Article?, pageNumber: Int, pdfData: Data?) {
        self.article = article
        self.pageNumber = pageNumber
        self.pdfData = pdfData
    }
    
    
    // MARK: - Hashable Implementation
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(pageNumber)
        hasher.combine(article)
    }
    
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: Page, rhs: Page) -> Bool {
        return lhs.pageNumber == rhs.pageNumber &&
               lhs.article == rhs.article
    }
}
