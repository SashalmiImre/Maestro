import Foundation
import PDFKit
import Algorithms

/// Egy publikáció reprezentációja, amely cikkeket tartalmaz és különböző layout variációkat tud generálni
class Publication {
    /// A publikáció neve (az alapmappa neve)
    let name: String
    
    /// A publikációhoz tartozó cikkek
    private var articles: [Article] = .init()
    
    /// A publikációhoz tartozó mappák struktúrája
    let folders: PublicationFolders
    
    /// Inicializálja a publikációt egy adott mappa alapján
    /// - Parameter folderURL: Az alapmappa URL-je
    /// - Returns: `nil`, ha nem sikerül létrehozni a publikációt (nincs érvényes cikk vagy hibás mappastruktúra)
    init?(folderURL: URL) {
        // Létrehozzuk a mappastruktúrát
        do {
            self.folders = try PublicationFolders(baseFolder: folderURL)
        } catch {
            print("Hiba a publikáció mappáinak létrehozásakor: \(error)")
            return nil
        }
        
        // A publikáció neve az alapmappa neve lesz
        self.name = folderURL.lastPathComponent
        
        // Megkeressük az érvényes almappákat
        let validSubfolders: [URL]
        do {
            validSubfolders = try folders.findValidSubfolders()
        } catch {
            print("Hiba a valid subfolderek keresése közben: \(error)")
            return nil
        }
        
        // Létrehozzuk a cikkeket az érvényes almappákból
        for folder in validSubfolders {
            if let inddFiles = try? Self.findInDesignFile(in: folder) {
                inddFiles.forEach { url in
                    if let article = Article(inddFile: url, availablePDFs: folders.availablePDFs) {
                        articles.append(article)
                    }
                }
            }
        }
        
        // Ha nincs egyetlen érvényes cikk sem, akkor nil-t adunk vissza
        guard !articles.isEmpty else { return nil }
    }
    
    /// Megkeresi az InDesign fájlt egy mappában
    /// - Parameter folderURL: A mappa URL-je
    /// - Returns: Az első talált InDesign fájl URL-je, vagy nil ha nincs ilyen
    /// - Throws: Fájlrendszer hibák esetén
    private static func findInDesignFile(in folderURL: URL) throws -> [URL]? {
        let contents = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )
        
        let result = contents.filter { $0.pathExtension.lowercased() == "indd" }
        return result.isEmpty ? nil : result
    }
    
    /// Visszaadja a publikáció lehetséges layout variációit
    /// - Returns: A generált layoutok tömbje
    func getLayouts() -> [Layout] {
        // Összegyűjtjük az összes oldalt és rendezzük oldalszám szerint
        let allPages = articles.flatMap { article in
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
