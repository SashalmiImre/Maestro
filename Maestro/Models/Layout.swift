import Foundation
import PDFKit

/// Layout: Egy kiadvány lehetséges oldalelrendezését reprezentáló típus.
/// Ez a struktúra felelős a cikkek oldalainak nyilvántartásáért és
/// az oldalütközések kezeléséért.
/// - Note: A struktúra Equatable és Hashable, hogy használható legyen Set és Dictionary típusokban
struct Layout: Equatable, Hashable {
    /// A layoutban tárolt cikkek gyűjteménye.
    /// Minden cikk csak egyszer szerepelhet, és nem lehet átfedés az oldalszámaik között.
    private var articles: [Article] = []
    
    /// Ellenőrzi, hogy a layout tartalmaz-e cikkeket
    /// - Returns: `true` ha a layout üres, `false` ha tartalmaz cikkeket
    var isEmpty: Bool {
        articles.isEmpty
    }
    
    /// Az összes oldal lekérése rendezett formában.
    /// A visszaadott tömb tartalmazza az összes oldal részletes információit,
    /// oldalszám szerint növekvő sorrendben.
    /// - Returns: Az oldalak tömbje, oldalszám szerint rendezve
    var pages: [Page] {
        articles
            .flatMap { $0.pages }
            .sorted { $0.pageNumber < $1.pageNumber }
    }
    
    /// A legnagyobb oldalszám, ami a layoutban szereplő cikkek között előfordul.
    /// Ez az érték a cikkek coverage property-jének upperBound értékeiből számolódik.
    /// - Returns: A legnagyobb oldalszám, vagy 0 ha nincs cikk a layoutban
    var maxPageNumber: Int {
        articles
            .map { $0.coverage.upperBound }
            .max() ?? 0
    }
    
    /// Kiszámolja a layoutban szereplő összes oldalszámot.
    /// Ez a szám megmutatja, hogy hány oldalt foglalnak el a cikkek összesen.
    /// - Returns: A cikkek által lefedett oldalak száma
    var pageCount: Int {
        // Mivel nincs átfedés a cikkek oldalai között, egyszerűen
        // összegezzük a cikkek által lefedett oldalak számát
        articles.reduce(0) { count, article in
            count + article.coverage.count
        }
    }
    
    /// Megpróbál hozzáadni egy új cikket a layouthoz.
    /// A metódus ellenőrzi, hogy van-e oldalszám-ütközés a már meglévő cikkekkel.
    ///
    /// - Parameter article: A hozzáadandó cikk
    /// - Returns: `true` ha sikerült a hozzáadás (nincs ütközés),
    ///           `false` ha ütközés miatt nem sikerült
    /// - Note: A @discardableResult attribútum lehetővé teszi, hogy
    ///        figyelmen kívül hagyjuk a visszatérési értéket, ha nem releváns
    @discardableResult
    mutating func add(_ article: Article) -> Bool {
        // Az Article.overlaps metódusával ellenőrizzük, hogy van-e ütközés
        // bármely már meglévő cikkel
        let hasNoConflict = !articles.contains { $0.overlaps(with: article) }
        
        // Csak akkor adjuk hozzá a cikket, ha nincs ütközés
        if hasNoConflict {
            articles.append(article)
            return true
        }
        
        return false
    }
    
    /// A layout oldalaiból létrehozott PagePair objektumok tömbje.
    /// Az oldalak párosítása a következő szabályok szerint történik:
    /// - A páros oldalak balra kerülnek
    /// - A páratlan oldalak jobbra kerülnek
    /// - Az oldalaknak egymás után kell következniük
    /// - Minden oldal létezik, üres oldalak is létrehozásra kerülnek
    func pagePairs(maxPageCount: Int) -> [PagePair] {
        let orderedPages = pages
        
        // Használjuk a maxPageCount értéket a teljes oldalszám meghatározásához
        // Ha a maxPageCount páratlan, akkor eggyel növeljük, hogy teljes oldalpárokat kapjunk
        let adjustedMaxPageCount = maxPageCount + (maxPageCount % 2)
        
        // Create a dictionary from existing pages for quick lookup
        let pageDict = Dictionary(uniqueKeysWithValues: orderedPages.map { ($0.pageNumber, $0) })
        
        // Create PagePairs from the total page range, using the adjusted max page count
        let pairs = stride(from: 0, to: adjustedMaxPageCount, by: 2).map { index -> PagePair in
            let leftPage = pageDict[index] ?? Page(article: nil, pageNumber: index, pdfPage: nil)
            let rightPage = pageDict[index + 1] ?? Page(article: nil, pageNumber: index + 1, pdfPage: nil)
            return PagePair(leftPage: leftPage, rightPage: rightPage)
        }
        
        return pairs
    }
    
    func maxPageSize(for displayBox: PDFDisplayBox) -> NSRect {
        var maxSize = NSRect.zero
        
        for page in pages {
            if let pdfPage = page.pdfPage?.page(at: 0) {
                let bounds = pdfPage.bounds(for: displayBox)
                maxSize.size.width = max(maxSize.size.width, bounds.width)
                maxSize.size.height = max(maxSize.size.height, bounds.height)
            }
        }
        
        return maxSize == .zero ? NSRect(x: 0, y: 0, width: 595, height: 842) : maxSize
    }
    
    // MARK: - Equatable Implementation
    
    static func == (lhs: Layout, rhs: Layout) -> Bool {
        lhs.articles == rhs.articles
    }
}
