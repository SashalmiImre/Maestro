//
//  Page.swift
//  Maestro
//
//  Created by Sashalmi Imre on 28/12/2024.
//

import PDFKit

actor Page {
    
    unowned let article: Article?
            let pageNumber: Int
            let pdfData: Data?
    
    nonisolated var pdfPage: PDFPage? {
        guard let data = pdfData else { return nil }
        return PDFDocument(data: data)?.page(at: 0)
    }
    
    init(pageNumber: Int, article: Article? = nil, pdfData: Data? = nil) {
        self.article    = article
        self.pageNumber = pageNumber
        self.pdfData    = pdfData
    }
}
