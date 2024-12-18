import Foundation
import SwiftUI

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
    private var layoutCache: [String: [Layout]] = [:]
    
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
    
    /// Ellenőrzi, hogy egy Article PDF fájlja megtalálható-e a workflow mappában
        func isPDFMissing(for articleName: String) -> Bool {
            // Ellenőrizzük, hogy létezik-e a PDF a __PDF__ mappában
            let pdfFolderURL = publication.pdfFolder
            let pdfURL = pdfFolderURL.appendingPathComponent("\(articleName).pdf")
            return !FileManager.default.fileExists(atPath: pdfURL.path)
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
        // Cache kulcs generálása az aktuális állapotból
        let cacheKey = publication.articles.map {
            "\($0.name)_\($0.startPage)_\($0.pages.count)"
        }.joined(separator: "|")
        
        // Ha van cache-elt eredmény, használjuk azt
        if let cachedLayouts = layoutCache[cacheKey] {
            return cachedLayouts
        }
        
        let articles = publication.articles
        guard !articles.isEmpty else { return [] }
        
        // Előfeldolgozás: oldalszámok és ütközések előkalkulálása
        let pageRanges = articles.map { article in
            (article, Set(article.pages.keys))
        }
        
        // Gyors ütközésvizsgálat
        let conflicts = findConflicts(in: pageRanges)
        
        // Article-ök csoportosítása az ütközések alapján
        let groupedArticles = classifyArticlesOptimized(articles, conflicts: conflicts)
        
        // Layout variációk generálása
        let layouts = generateLayoutVariationsOptimized(from: groupedArticles)
        
        // Eredmény cache-elése
        layoutCache[cacheKey] = layouts
        
        return layouts
    }
    
    /// Optimalizált ütközésvizsgálat
    private func findConflicts(in pageRanges: [(Article, Set<Int>)]) -> [String: Set<String>] {
        var conflicts: [String: Set<String>] = [:]
        
        for i in pageRanges.indices {
            let (article1, pages1) = pageRanges[i]
            
            for j in (i + 1)..<pageRanges.count {
                let (article2, pages2) = pageRanges[j]
                
                if !pages1.isDisjoint(with: pages2) {
                    conflicts[article1.name, default: []].insert(article2.name)
                    conflicts[article2.name, default: []].insert(article1.name)
                }
            }
        }
        
        return conflicts
    }
    
    /// Optimalizált Article osztályozás
    private func classifyArticlesOptimized(_ articles: [Article], conflicts: [String: Set<String>]) -> [ArticleType] {
        var result: [ArticleType] = []
        var processedArticles: Set<String> = []
        
        // Először a konfliktus nélküli cikkeket dolgozzuk fel
        for article in articles where !conflicts.keys.contains(article.name) {
            result.append(.fixed(article))
            processedArticles.insert(article.name)
        }
        
        // Majd a konfliktusosakat
        for article in articles where !processedArticles.contains(article.name) {
            result.append(.variable(article))
        }
        
        return result
    }
    
    /// Optimalizált layout variáció generálás
    private func generateLayoutVariationsOptimized(from articleTypes: [ArticleType]) -> [Layout] {
        var baseLayout = Layout()
        var fixedArticles: [Article] = []
        var variableArticles: [Article] = []
        
        // Gyorsabb szétválasztás
        for case let .fixed(article) in articleTypes {
            fixedArticles.append(article)
            for (pageNumber, pdfDocument) in article.pages {
                baseLayout.add(articleName: article.name, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
        }
        
        for case let .variable(article) in articleTypes {
            variableArticles.append(article)
        }
        
        if variableArticles.isEmpty {
            return [baseLayout]
        }
        
        // Párhuzamos feldolgozás nagy számú variáció esetén
        let combinations = generatePositionCombinations(for: variableArticles, baseLayout: baseLayout)
        
        return combinations.compactMap { combination in
            createValidLayout(baseLayout: baseLayout, combination: combination)
        }
    }
    
    /// Pozíció kombinációk generálása párhuzamosan
    private func generatePositionCombinations(for articles: [Article], baseLayout: Layout) -> [[ArticlePosition]] {
        let baseEndPage = baseLayout.layoutPages.map(\.pageNumber).max() ?? 0
        var combinations: [[ArticlePosition]] = [[]]
        
        for article in articles {
            let pageCount = article.pages.count
            let maxStartPage = baseEndPage + pageCount * articles.count
            
            var newCombinations: [[ArticlePosition]] = []
            
            for startPage in baseEndPage...(maxStartPage) {
                let position = ArticlePosition(
                    article: article,
                    startPage: startPage,
                    isFixed: false
                )
                
                for existing in combinations {
                    var new = existing
                    new.append(position)
                    newCombinations.append(new)
                }
            }
            
            combinations = newCombinations
        }
        
        return combinations
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
