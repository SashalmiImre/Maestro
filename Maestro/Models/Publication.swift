import Foundation
import PDFKit

class Publication {
    let name: String
    private var articles: [Article]
    let folders: PublicationFolders
    
    init?(folderURL: URL) {
        do {
            self.folders = try PublicationFolders(baseFolder: folderURL)
        } catch {
            print("Hiba a publikáció mappáinak létrehozásakor: \(error)")
            return nil
        }
        
        self.name = folderURL.lastPathComponent
        
        // Valid subfolderek keresése
        let validSubfolders: [URL]
        do {
            validSubfolders = try folders.findValidSubfolders()
        } catch {
            print("Hiba a valid subfolderek keresése közben: \(error)")
            return nil
        }
        
        // Article-ök létrehozása a valid subfolderekből
        var articles: [Article] = []
        for folder in validSubfolders {
            if let inddFile = try? Self.findInDesignFile(in: folder),
               let article = Article(inddFile: inddFile, searchFolders: folders.systemFolders) {
                articles.append(article)
            }
        }
        
        // Ha nincs egyetlen érvényes Article sem, akkor nil
        guard !articles.isEmpty else { return nil }
        self.articles = articles
    }
    
    private static func findInDesignFile(in folderURL: URL) throws -> URL? {
        let contents = try FileManager.default.contentsOfDirectory(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: .skipsHiddenFiles
        )
        
        return contents.first { $0.pathExtension.lowercased() == "indd" }
    }
    
    /// Visszaadja a publikáció layoutjait
    func getLayouts() -> [Layout] {
        // Összegyűjtjük az összes oldalt és megkeressük az ütközéseket
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
        
        // Csoportosítjuk az ütköző oldalakat cikkek szerint
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
        
        for variation in variations {
            var layout = Layout()
            
            // Először hozzáadjuk a nem ütköző oldalakat
            for (pageNumber, articles) in nonConflictingPages {
                let (articleName, pdfDocument) = articles[0]
                layout.add(articleName: articleName, pageNumber: pageNumber, pdfDocument: pdfDocument)
            }
            
            // Majd az ütköző oldalak aktuális variációját
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
    private func generateVariations(from groups: [[String: [(Int, PDFDocument)]]]) -> [[[String: [(Int, PDFDocument)]]]] {
        guard !groups.isEmpty else { return [] }
        
        var variations: [[[String: [(Int, PDFDocument)]]]] = [[groups[0]]]
        
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
