import Foundation
import PDFKit

/// Egy publikáció reprezentációja
@MainActor
class Publication: ObservableObject {
    // MARK: - Konstansok
    
    let name: String
    
    @Published var articles: [Article] = .init()
    
    let baseFolder: URL
    let pdfFolder: URL
    let layoutFolder: URL
    let correctedFolder: URL
    let printableFolder: URL
    let printedFolder: URL
    var workflowFolders: [URL] {
        [pdfFolder, layoutFolder, correctedFolder, printableFolder, printedFolder]
    }
    
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
