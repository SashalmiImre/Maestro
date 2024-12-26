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
    
    /// Ellenőrzi, hogy a layout tartalmaz-e cikkeket
    /// - Returns: `true` ha a layout üres, `false` ha tartalmaz cikkeket
    var isEmpty: Bool {
        articles.isEmpty
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
    
    /// Az összes oldal lekérése rendezett formában.
    /// A visszaadott tömb tartalmazza az összes oldal részletes információit,
    /// oldalszám szerint növekvő sorrendben.
    /// - Returns: Az oldalak tömbje, oldalszám szerint rendezve
    var pages: [Page] {
        var pages: [Page] = []
        // Végigmegyünk minden cikken és annak minden oldalán
        for article in articles {
            for (pageNumber, pdfDocument) in article.pages {
                pages.append(Page(
                    articleName: article.name,
                    pageNumber: pageNumber,
                    pdfDocument: pdfDocument,
                    pdfSource: article.pdfSource
                ))
            }
        }
        // Az oldalakat oldalszám szerint rendezzük
        return pages.sorted { $0.pageNumber < $1.pageNumber }
    }
    
    /// Egy konkrét oldal reprezentációja a layoutban.
    /// Tartalmazza az oldal minden szükséges adatát:
    /// a cikk nevét, az oldalszámot és a PDF dokumentumot.
    struct Page {
        /// A cikk neve, amihez az oldal tartozik
        let articleName: String
        /// Az oldal száma a kiadványban
        let pageNumber: Int
        /// Az oldalhoz tartozó PDF dokumentum
        let pdfDocument: PDFDocument
        /// Az oldalhoz tartozó PDF forrás URL
        let pdfSource: URL
    }
}
