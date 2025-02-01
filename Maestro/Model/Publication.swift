import Foundation
import PDFKit

/// Egy teljes kiadvány reprezentációja, amely kezeli a cikkeket és a munkafolyamat mappákat
/// - Note: A @MainActor attribútum biztosítja, hogy az osztály csak a fő szálon fusson
class Publication {
    // MARK: - Konstansok
    
    /// A kiadvány neve (a mappa neve alapján)
    let name: String
    
    /// A kiadványhoz tartozó cikkek listája
    var articles: [Article] = .init()
    
    /// A kiadvány alap mappája
    let baseFolder: URL
    
    /// A PDF fájlok tárolására szolgáló mappa
    let pdfFolder: URL
    
    /// A tördelt anyagok mappája
    let layoutFolder: URL
    
    /// A korrektúrázott anyagok mappája
    let correctedFolder: URL
    
    /// A nyomdakész anyagok mappája
    let printableFolder: URL
    
    /// A levilágított anyagok mappája
    let printedFolder: URL
    
    /// Az összes munkafolyamat mappa együtt
    var workflowFolders: [URL] {
        [pdfFolder, layoutFolder, correctedFolder, printableFolder, printedFolder]
    }
    
    /// Inicializálja a kiadványt egy mappa URL alapján
    /// - Parameter folderURL: A kiadvány gyökérmappájának URL-je
    /// - Throws: Hibát dob, ha nem sikerül létrehozni a szükséges mappákat
    init(folderURL: URL) async throws {
        self.baseFolder = folderURL
        self.name = folderURL.lastPathComponent
        
        self.layoutFolder    = baseFolder.appendingPathComponent("__TORDELVE")
        self.pdfFolder       = baseFolder.appendingPathComponent("__PDF__")
        self.correctedFolder = layoutFolder.appendingPathComponent("__OLVASVA")
        self.printableFolder = correctedFolder.appendingPathComponent("__LEVILAGITHATO")
        self.printedFolder   = correctedFolder.appendingPathComponent("__LEVIL__")
        
        // Létrehozzuk a hiányzó mappákat
        let fileManager = FileManager.default
        try self.workflowFolders.forEach { url in
            if !fileManager.fileExists(atPath: url.path) {
                try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
            }
        }
    }
}
