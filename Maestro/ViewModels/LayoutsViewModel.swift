import Foundation
import SwiftUI
import PDFKit

@MainActor
class LayoutsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// A rendelkezésre álló layoutok
    @Published private(set) var layouts: [Layout] = []
    
    /// A kiválasztott layout indexe
    @Published var selectedLayoutIndex: Int = 0
    
    /// Az aktuálisan kiválasztott layout
    var selectedLayout: Layout? {
        guard !layouts.isEmpty, selectedLayoutIndex >= 0, selectedLayoutIndex < layouts.count else {
            return nil
        }
        return layouts[selectedLayoutIndex]
    }
    
    // MARK: - Private Properties
    
    private let publication: Publication
    
    // MARK: - Initialization
    
    init(publication: Publication) {
        self.publication = publication
        refreshLayouts()
    }
    
    // MARK: - Public Methods
    
    /// Frissíti a layoutokat
    func refreshLayouts() {
        layouts = generateLayouts()
        // Ha a kiválasztott index érvénytelenné vált, visszaállítjuk 0-ra
        if selectedLayoutIndex >= layouts.count {
            selectedLayoutIndex = 0
        }
    }
    
    /// Visszaadja a layout variációk számát
    var layoutCount: Int {
        layouts.count
    }
    
    /// Ellenőrzi, hogy van-e következő layout
    var hasNextLayout: Bool {
        selectedLayoutIndex < layouts.count - 1
    }
    
    /// Ellenőrzi, hogy van-e előző layout
    var hasPreviousLayout: Bool {
        selectedLayoutIndex > 0
    }
    
    /// Átvált a következő layoutra
    func nextLayout() {
        guard hasNextLayout else { return }
        selectedLayoutIndex += 1
    }
    
    /// Átvált az előző layoutra
    func previousLayout() {
        guard hasPreviousLayout else { return }
        selectedLayoutIndex -= 1
    }
    
    /// Visszaadja a kiválasztott layout oldalainak számát
    var selectedLayoutPageCount: Int {
        selectedLayout?.pageCount ?? 0
    }
    
    /// Visszaadja a kiválasztott layout adott oldalszámához tartozó cikk nevét
    func articleName(forPage pageNumber: Int) -> String? {
        selectedLayout?.layoutPages.first { $0.pageNumber == pageNumber }?.articleName
    }
    
    /// Visszaadja a kiválasztott layout adott oldalszámához tartozó PDF dokumentumot
    func pdfDocument(forPage pageNumber: Int) -> PDFDocument? {
        selectedLayout?.layoutPages.first { $0.pageNumber == pageNumber }?.pdfDocument
    }
    
    // MARK: - Private Types
    
    /// Article típus az ütközések kezeléséhez
    private enum ArticleType {
        case fixed(Article)      // Állandó pozíciójú Article
        case variable(Article)   // Változó pozíciójú Article
    }
    
    /// Article pozíció egy layoutban
    private struct ArticlePosition {
        let article: Article
        let startPage: Int
        let isFixed: Bool
    }
    
    // MARK: - Private Methods
    
    /// Generálja a lehetséges layout variációkat
    private func generateLayouts() -> [Layout] {
        let articles = publication.articles
        if articles.isEmpty { return [] }
        
        // 1. Article-ök csoportosítása és rendezése oldalszám szerint
        let groupedArticles = classifyArticles(articles)
        
        // 2. Layout variációk generálása
        return generateLayoutVariations(from: groupedArticles)
    }
    
    /// Osztályozza az Article-öket fix és változó pozíciójúakra
    private func classifyArticles(_ articles: [Article]) -> [ArticleType] {
        // Oldalszám szerinti rendezés
        let sortedArticles = articles.sorted { article1, article2 in
            let firstPage1 = article1.pages.keys.min() ?? 0
            let firstPage2 = article2.pages.keys.min() ?? 0
            return firstPage1 < firstPage2
        }
        
        var result: [ArticleType] = []
        var usedPages: Set<Int> = []
        
        for article in sortedArticles {
            let pages = Set(article.pages.keys)
            let hasConflict = !pages.isDisjoint(with: usedPages)
            
            if hasConflict {
                // Ha van ütközés, változó pozíciójú lesz
                result.append(.variable(article))
            } else {
                // Ha nincs ütközés, fix pozíciójú marad
                result.append(.fixed(article))
                usedPages.formUnion(pages)
            }
        }
        
        return result
    }
    
    /// Generálja a layout variációkat a csoportosított Article-ök alapján
    private func generateLayoutVariations(from articleTypes: [ArticleType]) -> [Layout] {
        // Fix pozíciójú Article-ök egy alap layoutba
        var baseLayout = Layout()
        var fixedArticles: [Article] = []
        var variableArticles: [Article] = []
        
        // Article-ök szétválasztása
        for articleType in articleTypes {
            switch articleType {
            case .fixed(let article):
                fixedArticles.append(article)
                // Hozzáadjuk az alap layouthoz
                for (pageNumber, pdfDocument) in article.pages {
                    baseLayout.add(articleName: article.name, pageNumber: pageNumber, pdfDocument: pdfDocument)
                }
            case .variable(let article):
                variableArticles.append(article)
            }
        }
        
        // Ha nincs változó pozíciójú Article, csak az alap layout kell
        if variableArticles.isEmpty {
            return [baseLayout]
        }
        
        // Változó pozíciójú Article-ök lehetséges pozícióinak meghatározása
        var layouts: [Layout] = []
        var currentPage = (baseLayout.layoutPages.map { $0.pageNumber }.max() ?? 0) + 1
        
        // Pozíciók generálása a változó Article-ökhöz
        var articlePositions: [[ArticlePosition]] = []
        for article in variableArticles {
            let pageCount = article.pages.count
            var positions: [ArticlePosition] = []
            
            // Különböző kezdő pozíciók kipróbálása
            var startPage = currentPage
            while startPage <= currentPage + pageCount {
                positions.append(ArticlePosition(
                    article: article,
                    startPage: startPage,
                    isFixed: false
                ))
                startPage += 1
            }
            
            articlePositions.append(positions)
            currentPage += pageCount + 1  // Extra hely a következő Article-nek
        }
        
        // Layout kombinációk generálása
        generateLayoutCombinations(
            baseLayout: baseLayout,
            articlePositions: articlePositions,
            currentCombination: [],
            layouts: &layouts
        )
        
        return layouts
    }
    
    /// Rekurzívan generálja az összes lehetséges layout kombinációt
    private func generateLayoutCombinations(
        baseLayout: Layout,
        articlePositions: [[ArticlePosition]],
        currentCombination: [ArticlePosition],
        layouts: inout [Layout]
    ) {
        if currentCombination.count == articlePositions.count {
            if let layout = createValidLayout(baseLayout: baseLayout, combination: currentCombination) {
                layouts.append(layout)
            }
            return
        }
        
        let currentIndex = currentCombination.count
        for position in articlePositions[currentIndex] {
            var newCombination = currentCombination
            newCombination.append(position)
            generateLayoutCombinations(
                baseLayout: baseLayout,
                articlePositions: articlePositions,
                currentCombination: newCombination,
                layouts: &layouts
            )
        }
    }
    
    /// Létrehoz egy érvényes layoutot a fix és változó pozíciójú Article-ökből
    private func createValidLayout(baseLayout: Layout, combination: [ArticlePosition]) -> Layout? {
        var layout = baseLayout
        var usedPages = Set(baseLayout.layoutPages.map { $0.pageNumber })
        
        for position in combination {
            let offset = position.startPage - position.article.pages.first!.key
            
            // Ellenőrizzük, hogy az új pozíciók nem ütköznek-e
            let newPages = position.article.pages.keys.map { $0 + offset }
            if !Set(newPages).isDisjoint(with: usedPages) {
                return nil
            }
            
            // Hozzáadjuk az Article oldalait az új pozíciókban
            for (pageNumber, pdfDocument) in position.article.pages {
                let newPageNumber = pageNumber + offset
                layout.add(articleName: position.article.name, pageNumber: newPageNumber, pdfDocument: pdfDocument)
                usedPages.insert(newPageNumber)
            }
        }
        
        return layout
    }
} 
