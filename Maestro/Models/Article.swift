import Foundation
import PDFKit

struct Article: Equatable, Hashable {
    let name: String
    let inddFile: URL
    let coverage: ClosedRange<Int>
    var pages: [Int: PDFDocument]
    
    init?(inddFile: URL, availablePDFs: [URL]) {
        // Fájlnév feldolgozása
        let inddFileName = inddFile.deletingPathExtension().lastPathComponent
        guard let parsedName = FileNameParser.parse(fileName: inddFileName) else {
            return nil
        }
        
        self.name     = parsedName.articleName ?? inddFile.deletingPathExtension().lastPathComponent
        self.inddFile = inddFile
        self.coverage = parsedName.startPage...(parsedName.endPage ?? parsedName.startPage)
        
        // Keressük a leghasonlóbb nevű PDF-et az előre megtalált PDF-ek közül
        var bestMatch: (url: URL, similarity: Double)? = nil
        for pdfURL in availablePDFs {
            let pdfFileName = pdfURL.deletingPathExtension().lastPathComponent
            let similarity  = inddFileName.calculateSimilarity(with: pdfFileName)
            
            if similarity >= 0.9 && (bestMatch == nil || similarity > bestMatch!.similarity) {
                bestMatch = (pdfURL, similarity)
            }
        }
        
        guard let bestMatch = bestMatch,
              let pdfDocument = PDFDocument(url: bestMatch.url) else {
            return nil
        }
                
        // Oldalak feldolgozása
        self.pages = pdfDocument.collectingPages(coverage: coverage)
    }
    
    /// Ellenőrzi, hogy van-e átfedés két cikk között
    func overlaps(with other: Article) -> Bool {
        return self.coverage.overlaps(other.coverage)
    }
}
