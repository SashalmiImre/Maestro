import Foundation
import PDFKit
import Algorithms

/// Egy publikáció reprezentációja, amely cikkeket tartalmaz és különböző layout variációkat tud generálni
class Publication {
    /// A publikáció neve (az alapmappa neve)
    let name: String
    
    /// A publikációhoz tartozó cikkek
    private var articles: [Article]
    
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
        var articles: [Article] = []
        for folder in validSubfolders {
            if let inddFile = try? Self.findInDesignFile(in: folder),
               let article = Article(inddFile: inddFile, searchFolders: folders.systemFolders) {
                articles.append(article)
            }
        }
        
        // Ha nincs egyetlen érvényes cikk sem, akkor nil-t adunk vissza
        guard !articles.isEmpty else { return nil }
        self.articles = articles
    }
    
    /// Megkeresi az InDesign fájlt egy mappában
    /// - Parameter folderURL: A mappa URL-je
    /// - Returns: Az első talált InDesign fájl URL-je, vagy nil ha nincs ilyen
    /// - Throws: Fájlrendszer hibák esetén
    private static func findInDesignFile(in folderURL: URL) throws -> URL? {
        let contents = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )
        
        return contents.first { $0.pathExtension.lowercased() == "indd" }
    }
    
    /// Visszaadja a publikáció lehetséges layout variációit
    /// - Returns: A generált layoutok tömbje
    func getLayouts() -> [Layout] {
        // Összegyűjtjük az összes oldalt és rendezzük oldalszám szerint
        let allPages = articles.flatMap { article in
            article.pages.map { (article.name, $0.key, $0.value) }
        }.sorted { $0.1 < $1.1 }
        
        // Megszámoljuk, hogy melyik oldalszám hányszor fordul elő
        var pageNumberFrequency: [Int: [(String, PDFDocument)]] = [:]
        for (articleName, pageNumber, pdfDocument) in allPages {
            pageNumberFrequency[pageNumber, default: []].append((articleName, pdfDocument))
        }
        
        // Szétválasztjuk az ütköző és nem ütköző oldalakat
        let conflictingPages = pageNumberFrequency.filter { $0.value.count > 1 }
        let nonConflictingPages = pageNumberFrequency.filter { $0.value.count == 1 }
        
        // Az ütköző oldalakat cikkek szerint csoportosítjuk
        var conflictingArticleGroups: [[String: [(Int, PDFDocument)]]] = []
        for (pageNumber, articles) in conflictingPages {
            var articlePages: [String: [(Int, PDFDocument)]] = [:]
            for (articleName, pdfDocument) in articles {
                articlePages[articleName, default: []].append((pageNumber, pdfDocument))
            }
            conflictingArticleGroups.append(articlePages)
        }
        
        // Generáljuk a különböző layout variációkat
        var generatedLayouts: [Layout] = []
        let variations = generateVariations(from: conflictingArticleGroups)
        
        // Minden variációhoz létrehozunk egy layoutot
        for variation in variations {
            var layout = Layout()
            
            // A nem ütköző oldalakat minden layoutba ugyanúgy tesszük bele
            for (pageNumber, articles) in nonConflictingPages {
                let (articleName, pdfDocument) = articles[0]
                layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
            
            // Az ütköző oldalakat a variáció szerint adjuk hozzá
            for pages in variation {
                for (articleName, pageInfos) in pages {
                    for (pageNumber, pdfDocument) in pageInfos {
                        layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
                    }
                }
            }
            
            generatedLayouts.append(layout)
        }
        
        return generatedLayouts
    }
    
    /// Generálja az ütköző oldalak különböző variációit
    /// - Parameter groups: Az ütköző oldalak csoportjai
    /// - Returns: A lehetséges variációk tömbje
    private func generateVariations(from groups: [[String: [(Int, PDFDocument)]]]) -> [[[String: [(Int, PDFDocument)]]]] {
        guard !groups.isEmpty else { return [] }
        
        // Kezdetben csak az első csoport egy variációja van
        var variations: [[[String: [(Int, PDFDocument)]]]] = [[groups[0]]]
        
        // Minden további csoporthoz generáljuk az összes lehetséges kombinációt
        for i in 1..<groups.count {
            let currentGroup = groups[i]
            var newVariations: [[[String: [(Int, PDFDocument)]]]] = []
            
            for variation in variations {
                // Az aktuális csoport minden lehetséges sorrendjét hozzáadjuk
                let articleNames = Array(currentGroup.keys)
                let permutations = articleNames.permutations()
                
                for permutation in permutations {
                    var newVariation = variation
                    var newGroup: [String: [(Int, PDFDocument)]] = [:]
                    
                    for articleName in permutation {
                        newGroup[articleName] = currentGroup[articleName]
                    }
                    
                    newVariation.append(newGroup)
                    newVariations.append(newVariation)
                }
            }
            
            variations = newVariations
        }
        
        return variations
    }
}
