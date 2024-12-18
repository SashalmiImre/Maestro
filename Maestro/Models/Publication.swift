import Foundation
import PDFKit

/// Egy publikáció reprezentációja
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
    
    private(set) var availablePDFs: [URL] = []
    private(set) var availableInddFiles: [URL] = []
    
    init(folderURL: URL) throws {
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
    
    func refreshArticles() async {
        // Megkeressük az összes PDF-et és InDesign fájlt
        try? findAllFiles()
        
        // Létrehozzuk a cikkeket az InDesign fájlok alapján
        for inddFile in self.availableInddFiles {
            if let article = Article(inddFile: inddFile, availablePDFs: self.availablePDFs) {
                articles.append(article)
            }
        }
    }
    
    /// Megkeresi az első szintű érvényes almappákat a base mappában (workflow mappák nélkül)
    private func findValidSubfolders() throws -> [URL] {
        // Csak az első szintű tartalom lekérése (nem rekurzív)
        let contents = try FileManager.default.contentsOfDirectory(
            at: baseFolder,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .tagNamesKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        let nemKellPattern = #"^(?i)nemkell$"#
        
        return try contents.filter { folderURL in
            let resourceValues = try folderURL.resourceValues(forKeys: [
                .isDirectoryKey,
                .isHiddenKey,
                .tagNamesKey
            ])
            
            let isDirectory = resourceValues.isDirectory ?? false
            let isHidden = resourceValues.isHidden ?? false
            let tags = resourceValues.tagNames ?? []
            let hasGrayTag = tags.contains("Gray") || tags.contains("Grey")
            let isNemKell = folderURL.lastPathComponent.matches(of: try! Regex(nemKellPattern)).count > 0
            
            // Kizárjuk a workflow mappákat is
            let isWorkflowFolder = workflowFolders.contains { workflowFolder in
                folderURL.path == workflowFolder.path
            }
            
            return isDirectory && !isHidden && !hasGrayTag && !isNemKell && !isWorkflowFolder
        }
    }
    
    /// Megkeresi az összes PDF és InDesign fájlt, először a workflow mappákban,
    /// majd a többi mappában, de csak a nem hasonló nevűeket
    private func findAllFiles() throws {
        // 1. Először a workflow mappák feldolgozása
        for workflowFolder in workflowFolders {
            if let enumerator = FileManager.default.enumerator(
                at: workflowFolder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let ext = fileURL.pathExtension.lowercased()
                    if ext == "pdf" {
                        availablePDFs.append(fileURL)
                    } else if ext == "indd" {
                        availableInddFiles.append(fileURL)
                    }
                }
            }
        }
        
        // 2. Többi érvényes mappa feldolgozása
        let otherFolders = try findValidSubfolders()
        
        // Segédfüggvény a név hasonlóság ellenőrzésére
        func isNameTooSimilar(_ fileName: String, to existingFiles: [URL]) -> Bool {
            for existingFile in existingFiles {
                let existingName = existingFile.deletingPathExtension().lastPathComponent
                if fileName.calculateSimilarity(with: existingName) > 0.9 {
                    return true
                }
            }
            return false
        }
        
        // Többi mappa feldolgozása
        for otherFolder in otherFolders {
            if let enumerator = FileManager.default.enumerator(
                at: otherFolder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let fileExtension = fileURL.pathExtension.lowercased()
                    let fileName = fileURL.deletingPathExtension().lastPathComponent
                    
                    if fileExtension == "pdf" {
                        // Csak akkor adjuk hozzá, ha nincs hasonló nevű
                        if !isNameTooSimilar(fileName, to: availablePDFs) {
                            availablePDFs.append(fileURL)
                        }
                    } else if fileExtension == "indd" {
                        // Csak akkor adjuk hozzá, ha nincs hasonló nevű
                        if !isNameTooSimilar(fileName, to: availableInddFiles) {
                            availableInddFiles.append(fileURL)
                        }
                    }
                }
            }
        }
    }
}
