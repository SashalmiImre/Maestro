import Foundation
import PDFKit

/// Egy újságcikk modellje, amely tartalmazza a cikk nevét, fájljait és oldalszámozását
/// - Note: A struktúra Equatable és Hashable, hogy könnyen használható legyen kollekciókban
struct Article: Equatable, Hashable {
    /// A cikk neve, ami vagy a fájlnévből kerül kinyerésre, vagy maga a fájlnév
    let name: String
    
    /// A cikk InDesign fájljának URL-je
    let inddFile: URL
    
    /// A cikk által lefedett oldalszámok tartománya
    let coverage: ClosedRange<Int>
    
    /// A cikk PDF oldalai, ahol a kulcs az oldalszám
    var pages: [Int: PDFDocument]
    
    /// A cikk PDF forrásának URL-je
    let pdfSource: URL
    
    /// Inicializálja a cikket egy InDesign fájl és az elérhető PDF-ek alapján
    /// - Parameters:
    ///   - inddFile: Az InDesign fájl URL-je
    ///   - availablePDFs: Az elérhető PDF fájlok URL-jeinek tömbje
    /// - Returns: Nil, ha a fájlnév nem dolgozható fel vagy nem található megfelelő PDF
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
        // Csak akkor fogadjuk el, ha legalább 90%-os a hasonlóság
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
                
        // Store the PDF source
        self.pdfSource = bestMatch.url
        
        // Oldalak feldolgozása és tárolása
        self.pages = pdfDocument.collectingPages(coverage: coverage)
    }
    
    /// Ellenőrzi, hogy van-e átfedés két cikk között az oldalszámozásban
    /// - Parameter other: A másik cikk, amivel az átfedést vizsgáljuk
    /// - Returns: True, ha van átfedés a két cikk oldalszámai között
    func overlaps(with other: Article) -> Bool {
        return self.coverage.overlaps(other.coverage)
    }
}
