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
    
    // MARK: - Private Methods
    
    /// Generálja a lehetséges layout variációkat
    private func generateLayouts() -> [Layout] {
        // Összegyűjtjük az összes oldalt és rendezzük oldalszám szerint
        let allPages = publication.articles.flatMap { article in
            article.pages.map { (article.name, $0.key, $0.value) }
        }.sorted { $0.1 < $1.1 }
        
        // Oldalszámok gyakorisága
        var pageNumberFrequency: [Int: [(String, PDFDocument)]] = [:]
        for (articleName, pageNumber, pdfDocument) in allPages {
            pageNumberFrequency[pageNumber, default: []].append((articleName, pdfDocument))
        }
        
        // Különválasztjuk az ütköző és nem ütköző oldalakat
        let conflictingPages = pageNumberFrequency.filter { $0.value.count > 1 }
        let nonConflictingPages = pageNumberFrequency.filter { $0.value.count == 1 }
        
        // Ha nincs ütközés, csak egy layout van
        if conflictingPages.isEmpty {
            var layout = Layout()
            for (pageNumber, articles) in nonConflictingPages {
                let (articleName, pdfDocument) = articles[0]
                layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
            return [layout]
        }
        
        // Ütköző oldalak csoportosítása oldalszám szerint
        var conflicts: [Int: [(String, PDFDocument)]] = [:]
        for (pageNumber, articles) in conflictingPages {
            conflicts[pageNumber] = articles
        }
        
        // Generáljuk a lehetséges választásokat minden ütköző oldalszámhoz
        var layoutChoices: [[Int: (String, PDFDocument)]] = [[:]]
        
        for (pageNumber, articles) in conflicts {
            var newChoices: [[Int: (String, PDFDocument)]] = []
            
            for choice in layoutChoices {
                for (articleName, pdfDocument) in articles {
                    var newChoice = choice
                    newChoice[pageNumber] = (articleName, pdfDocument)
                    newChoices.append(newChoice)
                }
            }
            
            layoutChoices = newChoices
        }
        
        // Generáljuk a layoutokat a választások alapján
        var layouts: [Layout] = []
        
        for choices in layoutChoices {
            var layout = Layout()
            
            // Nem ütköző oldalak hozzáadása (minden layoutban ugyanaz)
            for (pageNumber, articles) in nonConflictingPages {
                let (articleName, pdfDocument) = articles[0]
                layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
            
            // Ütköző oldalak hozzáadása a választások szerint
            for (pageNumber, articleInfo) in choices {
                let (articleName, pdfDocument) = articleInfo
                layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
            
            layouts.append(layout)
        }
        
        return layouts
    }
} 
