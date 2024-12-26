import Foundation
import PDFKit

/// Layout: Egy kiadvány lehetséges oldalelrendezését reprezentáló típus.
/// Ez a struktúra felelős a cikkek oldalainak nyilvántartásáért és
/// az oldalütközések kezeléséért.
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
        //let hasConflict = articles.contains { article.overlaps(with: $0) }
        let hasNoConflict = !articles.contains { $0.overlaps(with: article) }

        // Ütközés esetén false-szal térünk vissza, de nem módosítjuk a layoutot
        if hasNoConflict {
            articles.append(article)
            return true
        }
        
        return false
    }
    
    /// Ellenőrzi, hogy a layout tartalmaz-e cikkeket
    var isEmpty: Bool {
        articles.isEmpty
    }
    
    /// Kiszámolja a layoutban szereplő összes oldalszámot.
    /// Ez a szám megmutatja, hogy hány oldalt foglalnak el a cikkek összesen.
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
    var pages: [Page] {
        var pages: [Page] = []
        // Végigmegyünk minden cikken és annak minden oldalán
        for article in articles {
            for (pageNumber, pdfDocument) in article.pages {
                pages.append(Page(
                    articleName: article.name,
                    pageNumber: pageNumber,
                    pdfDocument: pdfDocument
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
    }
}
