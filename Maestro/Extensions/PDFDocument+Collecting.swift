import PDFKit

extension PDFDocument {
    /// Összegyűjti és feldolgozza a PDF oldalait egyedi oldalakká
    /// - Parameters:
    ///   - startPage: A kezdő oldalszám
    ///   - endPage: A záró oldalszám
    /// - Returns: A feldolgozott oldalak szótára, ahol a kulcs az oldalszám
    func collectingPages(startPage: Int, endPage: Int) -> [Int: PDFDocument] {
        var processedPages: [Int: PDFDocument] = [:]
        var currentPage = startPage
        var pdfPageIndex = 0
        
        while currentPage <= endPage {
            guard let pdfPage = self.page(at: pdfPageIndex) else { break }
            
            switch (currentPage, startPage, endPage) {
            case (currentPage, startPage, endPage)
                where (currentPage == startPage && startPage % 2 == 1) ||  // Páratlan kezdőoldal
                      (currentPage == endPage && endPage % 2 == 0):        // Páros záróoldal
                // Teljes oldal másolása
                if let fullPagePDF = pdfPage.createPDF(side: .full) {
                    processedPages[currentPage] = fullPagePDF
                }
                
            default:
                // Bal oldali fél
                if let leftPagePDF = pdfPage.createPDF(side: .left) {
                    processedPages[currentPage] = leftPagePDF
                }
                
                currentPage += 1  // Extra növelés a féloldalas esetben
                
                // Jobb oldali fél (ha nem az utolsó oldalnál vagyunk)
                if currentPage <= endPage, let rightPagePDF = pdfPage.createPDF(side: .right) {
                    processedPages[currentPage] = rightPagePDF
                }
            }
            
            currentPage += 1     // Alap növelés minden esetben
            pdfPageIndex += 1
        }
        
        return processedPages
    }
} 