//
//  AppState.swift
//  Maestro
//
//  Created by Sashalmi Imre on 21/12/2024.
//

import SwiftUI
import Algorithms

/// Az alkalmazás állapotkezelője, amely felelős a kiadvány és annak lehetséges
/// oldalelrendezéseinek kezeléséért.
class AppState: ObservableObject {
    // MARK: - Published Properties
    
    /// Az aktuálisan betöltött kiadvány
    @Published var publication: Publication?
    
    /// A kiadvány lehetséges oldalelrendezései
    /// Csak olvasható kívülről, a generateLayouts() függvény frissíti
    @Published private(set) var layouts: [Layout] = []
    
    // MARK: - Private Properties
    
    /// Cache a már kiszámolt layout-oknak
    /// A kulcs egy egyedi string azonosító, ami a cikkek neveiből és oldalszámaiból áll
    private var layoutCache: [String: [Layout]] = [:]
    
    // MARK: - Initialization
    
    /// Inicializálja az állapotkezelőt és legenerálja az első layout-okat
    init() {
        layouts = generateLayouts()
    }
    
    func refreshLayouts() {
        layouts = generateLayouts()
    }
    
    /// Generálja a lehetséges layout variációkat a publikáció cikkeiből
    /// A függvény figyelembe veszi az oldalszám-ütközéseket és optimalizál a cache használatával
    ///
    /// - Returns: A lehetséges layout-ok tömbje
    private func generateLayouts() -> [Layout] {
        // Ellenőrizzük, hogy van-e érvényes publikáció és vannak-e benne cikkek
        guard let publication = publication,
              !publication.articles.isEmpty else { return .init() }
        let articles = publication.articles
        
        // Generálunk egy egyedi kulcsot a cache-hez a cikkek alapján
        let cacheKey = articles.map {
            "\($0.name)_\($0.coverage)"
        }.sorted().joined(separator: "|")
        
        // Ha már van cache-elt eredmény, visszaadjuk azt
        if let cachedLayouts = layoutCache[cacheKey] {
            return cachedLayouts
        }
        
        // Szétválasztjuk a cikkeket ütközők és nem ütközők csoportjára
        let (nonConflictingArticles, conflictingArticles) = findArticleConflicts(articles)
        
        // Létrehozzuk az alap layout-ot a nem ütköző cikkekkel
        var baseLayout = Layout()
        for article in nonConflictingArticles {
            baseLayout.add(article)
        }
        
        // Ha nincs ütköző cikk, nincs szükség további variációk generálására
        if conflictingArticles.isEmpty {
            return [baseLayout]
        }
        
        var allLayouts: [Layout] = []
        
        // Az ütköző cikkek minden lehetséges sorrendjét kipróbáljuk
        let permutations = conflictingArticles.permutations()
        
        for permutation in permutations {
            var layout = baseLayout
            var isValid = true
            
            // Megpróbáljuk hozzáadni az ütköző cikkeket az aktuális sorrendben
            for article in permutation {
                if !layout.add(article) {
                    isValid = false
                    break
                }
            }
            
            // Ha sikerült minden cikket hozzáadni, mentjük a layout-ot
            if isValid {
                allLayouts.append(layout)
            }
        }
        
        // Frissítjük a cache-t az új eredményekkel
        layoutCache[cacheKey] = allLayouts
        
        // Ha nem találtunk érvényes kombinációt, visszaadjuk az alap layout-ot
        return allLayouts.isEmpty ? [baseLayout] : allLayouts
    }
    
    /// Szétválasztja a cikkeket ütkö és nem ütköző csoportokra
    /// Egy cikk akkor ütközik, ha van olyan másik cikk, amellyel átfedésben van az oldalszámozása
    ///
    /// - Parameter articles: A vizsgálandó cikkek tömbje
    /// - Returns: Tuple, ami tartalmazza a nem ütköző és ütköző cikkek tömbjeit
    private func findArticleConflicts(_ articles: [Article]) -> (nonConflicting: [Article], conflicting: [Article]) {
        var nonConflicting: [Article] = []
        var conflicting: [Article] = []
        
        for article in articles {
            // Ellenőrizzük, hogy a cikk ütközik-e bármely másik cikkel
            let hasConflict = articles
                .filter { $0.name != article.name } // Kihagyjuk önmagát
                .contains { article.overlaps(with: $0) }
            
            // Az eredmény alapján kategorizáljuk a cikket
            if hasConflict {
                conflicting.append(article)
            } else {
                nonConflicting.append(article)
            }
        }
        
        return (nonConflicting, conflicting)
    }
}
