import PDFKit

extension PDFDocument {
    /// Összegyűjti és feldolgozza a PDF oldalait egyedi oldalakká
    /// - Parameters:
    ///   - coverage: Az oldalszámokat tartalmazó zárt tartomány
    /// - Returns: A feldolgozott oldalak szótára, ahol a kulcs az oldalszám, vagy hiba esetén az adott hiba
    func collectingPages(coverage: ClosedRange<Int>) -> Result<[Int: PDFDocument], PageColletingError> {
        var processedPages: [Int: PDFDocument] = [:]
        let pdfPageCount  = self.pageCount
        let coverageCount = coverage.count
        
        // Ellenőrizzük a coverage tartomány érvényességét
        guard coverage.lowerBound > 0 else {
            // Érvénytelen tartomány
            return .failure(.invalidCoverageRange)
        }
        
        // Ellenőrizzük a coverage és PDF oldalak arányát
        let ratio = Double(coverageCount) / Double(pdfPageCount)
        guard ratio >= 1.0, ratio <= 2.0 else {
            // Hibás állapot: túl kevés vagy túl sok oldalt kérünk
            return ratio < 1.0 ? .failure(.tooFewPagesRequested) : .failure(.tooManyPagesRequested)
        }
        
        enum PageType {
            case single
            case spread
            
            static func determine(for page: PDFPage) -> PageType {
                // Ha az oldal szélessége nagyobb mint a magassága,
                // akkor valószínűleg egy oldalpárról van szó
                return page.bounds(for: .trimBox).width > page.bounds(for: .trimBox).height
                    ? .spread
                    : .single
            }
        }
        
        var currentPage = coverage.lowerBound
        
        // Oldalak feldolgozása
        for pdfPageIndex in 0..<pdfPageCount {
            guard let pdfPage = self.page(at: pdfPageIndex) else { continue }
            
            let pageType = PageType.determine(for: pdfPage)
            
            switch pageType {
            case .single:
                if let fullPagePDF = pdfPage.createPDF(side: .full) {
                    processedPages[currentPage] = fullPagePDF
                    currentPage += 1
                }
                
            case .spread:
                // Bal oldali fél
                if let leftPagePDF = pdfPage.createPDF(side: .left) {
                    processedPages[currentPage] = leftPagePDF
                }
                
                currentPage += 1
                
                // Jobb oldali fél
                if currentPage <= coverage.upperBound,
                   let rightPagePDF = pdfPage.createPDF(side: .right) {
                    processedPages[currentPage] = rightPagePDF
                    currentPage += 1
                }
            }
        }
        
        // Ellenőrizzük, hogy minden kért oldalt sikerült-e feldolgozni
        guard processedPages.count == coverageCount else {
            return .failure(.unexpectedPageCount)
        }
        
        return .success(processedPages)
    }
}

extension PDFDocument {
    enum PageColletingError: Error {
        case invalidCoverageRange
        case tooManyPagesRequested
        case tooFewPagesRequested
        case unexpectedPageCount
    }
}
