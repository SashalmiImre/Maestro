import Foundation
import PDFKit

struct Article {
    let name: String
    let startPage: Int
    let endPage: Int
    var pages: [Int: PDFDocument]
    
    init?(inddFile: URL, searchFolders: [URL]) {
        // Fájlnév feldolgozása
        guard let parsedName = FileNameParser.parse(fileName: inddFile.deletingPathExtension().lastPathComponent) else {
            return nil
        }
        
        self.name = parsedName.articleName ?? inddFile.deletingPathExtension().lastPathComponent
        self.startPage = parsedName.startPage
        self.endPage = parsedName.endPage ?? parsedName.startPage
        
        // PDF dokumentum keresése és oldalak feldolgozása
        guard let pdfDocument = Self.findPDFDocument(for: inddFile, in: searchFolders) else {
            return nil
        }
        
        self.pages = pdfDocument.collectingPages(startPage: startPage, endPage: endPage)
    }
    
    private static func findPDFDocument(for inddFile: URL, in searchFolders: [URL]) -> PDFDocument? {
        let inddName = inddFile.deletingPathExtension().lastPathComponent
        
        // A Publication főmappája (egy szinttel feljebb a keresési mappáktól)
        if let publicationFolder = searchFolders.first?.deletingLastPathComponent() {
            // Először keressük a __PDF mappában
            let pdfFolder = publicationFolder.appendingPathComponent("__PDF")
            if let pdfDocument = findSimilarPDF(inddName: inddName, in: pdfFolder) {
                return pdfDocument
            }
        }
        
        // Ha nincs a __PDF mappában, keressük a keresési mappákban
        for folder in searchFolders {
            if let pdfDocument = findSimilarPDF(inddName: inddName, in: folder) {
                return pdfDocument
            }
        }
        
        return nil
    }
    
    private static func findSimilarPDF(inddName: String, in folder: URL) -> PDFDocument? {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return nil
        }
        
        let pdfFiles = contents.filter { $0.pathExtension.lowercased() == "pdf" }
        
        // Keressük a leghasonlóbb nevű PDF-et
        var bestMatch: (url: URL, similarity: Double)? = nil
        
        for pdfURL in pdfFiles {
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
        
        if let bestMatch = bestMatch {
            print("Végső választás: \(bestMatch.url.lastPathComponent) (\(bestMatch.similarity * 100)% egyezés)")
            return PDFDocument(url: bestMatch.url)
        }
        
        return nil
    }
} 
