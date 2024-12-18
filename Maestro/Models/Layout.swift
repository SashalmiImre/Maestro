import Foundation
import PDFKit

struct Layout {
    /// Egy oldal reprezentációja a layoutban
    struct Page {
        let articleName: String
        let pageNumber: Int
        let pdfDocument: PDFDocument
    }
    
    /// A layout oldalai
    private var pages: [Page] = []
    
    /// A használt oldalszámok halmaza
    private var usedPageNumbers: Set<Int> = []
    
    /// Ellenőrzi, hogy egy oldalszám hozzáadható-e a layouthoz
    /// - Parameter pageNumber: Az ellenőrizendő oldalszám
    /// - Returns: `true` ha hozzáadható, `false` ha nem
    func canAdd(pageNumber: Int) -> Bool {
        !usedPageNumbers.contains(pageNumber)
    }
    
    /// Hozzáad egy oldalt a layouthoz
    /// - Parameters:
    ///   - articleName: A cikk neve
    ///   - pageNumber: Az oldalszám
    ///   - pdfDocument: A PDF dokumentum
    mutating func add(articleName: String, pageNumber: Int, pdfDocument: PDFDocument) {
        pages.append(Page(
            articleName: articleName,
            pageNumber: pageNumber,
            pdfDocument: pdfDocument
        ))
        usedPageNumbers.insert(pageNumber)
    }
    
    /// Ellenőrzi, hogy a layout üres-e
    var isEmpty: Bool {
        pages.isEmpty
    }
    
    /// A layout oldalainak száma
    var pageCount: Int {
        pages.count
    }
    
    /// Az oldalak lekérése
    var layoutPages: [Page] {
        pages.sorted { $0.pageNumber < $1.pageNumber }
    }
} 
