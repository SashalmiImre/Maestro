import Foundation
import PDFKit

struct Article {
    let name: String
    let startPage: Int
    let endPage: Int
    var pages: [Int: PDFDocument]
    
    init?(inddFile: URL, availablePDFs: [URL]) {
        // Fájlnév feldolgozása
        guard let parsedName = FileNameParser.parse(fileName: inddFile.deletingPathExtension().lastPathComponent) else {
            return nil
        }
        
        self.name = parsedName.articleName ?? inddFile.deletingPathExtension().lastPathComponent
        self.startPage = parsedName.startPage
        self.endPage = parsedName.endPage ?? parsedName.startPage
        
        // PDF dokumentum keresése az előre megtalált PDF-ek közül
        let inddName = inddFile.deletingPathExtension().lastPathComponent
        
        // Keressük a leghasonlóbb nevű PDF-et az előre megtalált PDF-ek közül
        var bestMatch: (url: URL, similarity: Double)? = nil
        
        for pdfURL in availablePDFs {
            let pdfName = pdfURL.deletingPathExtension().lastPathComponent
            let similarity = inddName.calculateSimilarity(with: pdfName)
            
            // Frissítjük a best match-et, ha:
            // 1. A hasonlóság legalább 90% ÉS
            // 2. Vagy még nincs best match, vagy ez jobb, mint az eddigi legjobb
            if similarity >= 0.9 && (bestMatch == nil || similarity > bestMatch!.similarity) {
                bestMatch = (pdfURL, similarity)
                print("Új legjobb találat: \(pdfName) (\(similarity * 100)% egyezés)")
            }
        }
        
        guard let bestMatch = bestMatch,
              let pdfDocument = PDFDocument(url: bestMatch.url) else {
            return nil
        }
        
        print("Végső választás: \(bestMatch.url.lastPathComponent) (\(bestMatch.similarity * 100)% egyezés)")
        
        // Oldalak feldolgozása
        self.pages = pdfDocument.collectingPages(startPage: startPage, endPage: endPage)
    }
} 
