import Foundation
import PDFKit
import Algorithms

/// Egy publikáció reprezentációja, amely cikkeket tartalmaz és különböző layout variációkat tud generálni
class Publication {
    /// A publikáció neve (az alapmappa neve)
    let name: String
    
    /// A publikációhoz tartozó cikkek
    var articles: [Article] { _articles }
    private var _articles: [Article] = []
    
    /// A publikációhoz tartozó mappák struktúrája
    let folders: PublicationFolders
    
    /// Inicializálja a publikációt egy adott mappa alapján
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
        
        // Létrehozzuk a cikkeket az InDesign fájlok alapján
        for inddFile in folders.availableInddFiles {
            if let article = Article(inddFile: inddFile, availablePDFs: folders.availablePDFs) {
                _articles.append(article)
            }
        }
        
        // Ha nincs egyetlen érvényes cikk sem, akkor nil-t adunk vissza
        guard !_articles.isEmpty else { return nil }
    }
}
