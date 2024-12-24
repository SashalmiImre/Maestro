import PDFKit

extension PDFDocument {
    /// Összegyűjti és feldolgozza a PDF oldalait egyedi oldalakká
    /// - Parameters:
    ///   - startPage: A kezdő oldalszám
    ///   - endPage: A záró oldalszám
    /// - Returns: A feldolgozott oldalak szótára, ahol a kulcs az oldalszám
    func collectingPages(coverage: ClosedRange<Int>) -> [Int: PDFDocument] {
        var processedPages: [Int: PDFDocument] = [:]
        var currentPage = coverage.lowerBound
        var pdfPageIndex = 0
        
        while currentPage <= coverage.upperBound {
            guard let pdfPage = self.page(at: pdfPageIndex) else { break }
            
            switch (currentPage, coverage) {
            case (currentPage, coverage)
                where (currentPage == coverage.lowerBound && coverage.lowerBound % 2 == 1) ||  // Páratlan kezdőoldal
                (currentPage == coverage.upperBound && coverage.upperBound % 2 == 0):          // Páros záróoldal
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
                if currentPage <= coverage.upperBound,
                   let rightPagePDF = pdfPage.createPDF(side: .right) {
                    processedPages[currentPage] = rightPagePDF
                }
            }
            
            currentPage += 1
            pdfPageIndex += 1
        }
        
        return processedPages
    }
}
