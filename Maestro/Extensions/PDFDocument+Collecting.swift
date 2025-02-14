import PDFKit

extension PDFDocument {
    /// Összegyűjti és feldolgozza a PDF oldalait egyedi oldalakká
    /// - Parameters:
    ///   - coverage: Az oldalszámokat tartalmazó zárt tartomány
    ///   - displayBox: A PDF oldalak határainak meghatározásához használt doboz típusa
    /// - Returns: A feldolgozott oldalak szótára, ahol a kulcs az oldalszám, vagy hiba esetén az adott hiba
    func collectingPages(coverage: ClosedRange<Int>, displayBox: PDFDisplayBox) -> Result<[Int: PDFPage], PageColletingError> {
        var processedPages: [Int: PDFPage] = [:]
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
            
            static func determine(for page: PDFPage, displayBox: PDFDisplayBox) -> PageType {
                // Ha az oldal szélessége nagyobb mint a magassága,
                // akkor valószínűleg egy oldalpárról van szó
                return page.bounds(for: displayBox).width > page.bounds(for: displayBox).height
                    ? .spread
                    : .single
            }
        }
        
        var currentPage = coverage.lowerBound
        
        // Oldalak feldolgozása
        for pdfPageIndex in 0..<pdfPageCount {
            guard let pdfPage = self.page(at: pdfPageIndex) else { continue }
            
            let pageType = PageType.determine(for: pdfPage, displayBox: displayBox)
            
            switch pageType {
            case .single:
                if let fullPagePDF = pdfPage.createPDF(side: .full, displayBox: displayBox) {
                    processedPages[currentPage] = fullPagePDF.page(at: 0)
                    currentPage += 1
                }
                
            case .spread:
                // Bal oldali fél
                if let leftPagePDF = pdfPage.createPDF(side: .left, displayBox: displayBox) {
                    processedPages[currentPage] = leftPagePDF.page(at: 0)
                }
                
                currentPage += 1
                
                // Jobb oldali fél
                if currentPage <= coverage.upperBound,
                   let rightPagePDF = pdfPage.createPDF(side: .right, displayBox: displayBox) {
                    processedPages[currentPage] = rightPagePDF.page(at: 0)
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
