import Foundation

struct PublicationFolders {
    // MARK: - Konstansok
    
    private enum Constants {
        /// A fájlnév hasonlóság küszöbértéke (0.0 - 1.0)
        static let similarityThreshold: Double = 0.8
        
        /// Támogatott fájlkiterjesztések
        enum FileExtensions {
            static let pdf = "pdf"
            static let indd = "indd"
        }
    }
    
    // MARK: - Properties
    
    let baseFolder: URL
    let pdfFolder: URL
    let layoutFolder: URL
    let correctedFolder: URL
    let printableFolder: URL
    let printedFolder: URL
    private(set) var availablePDFs: [URL] = []
    private(set) var availableInddFiles: [URL] = []
    
    init(baseFolder: URL) throws {
        self.baseFolder = baseFolder
        
        // Fix almappák létrehozása
        self.layoutFolder = baseFolder.appendingPathComponent("__TORDELVE")
        self.pdfFolder = baseFolder.appendingPathComponent("__PDF__")
        self.correctedFolder = layoutFolder.appendingPathComponent("__OLVASVA")
        self.printableFolder = correctedFolder.appendingPathComponent("__LEVILAGITHATO")
        self.printedFolder = correctedFolder.appendingPathComponent("__LEVIL__")
        
        // Létrehozzuk a hiányzó mappákat
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: layoutFolder.path) {
            try fileManager.createDirectory(at: layoutFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: pdfFolder.path) {
            try fileManager.createDirectory(at: pdfFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: correctedFolder.path) {
            try fileManager.createDirectory(at: correctedFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: printableFolder.path) {
            try fileManager.createDirectory(at: printableFolder, withIntermediateDirectories: true)
        }
        
        if !fileManager.fileExists(atPath: printedFolder.path) {
            try fileManager.createDirectory(at: printedFolder, withIntermediateDirectories: true)
        }
        
        // Megkeressük az összes PDF-et és InDesign fájlt
        try findAllFiles()
    }
    
    /// Visszaadja az összes munkafolyamat mappát
    var workflowFolders: [URL] {
        [pdfFolder, layoutFolder, correctedFolder, printableFolder, printedFolder]
    }
    
    /// Megkeresi az első szintű érvényes almappákat a base mappában (workflow mappák nélkül)
    func findValidSubfolders() throws -> [URL] {
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
    private mutating func findAllFiles() throws {
        var pdfs: [URL] = []
        var indds: [URL] = []
        
        // 1. Először a workflow mappák feldolgozása
        for workflowFolder in workflowFolders {
            if let enumerator = FileManager.default.enumerator(
                at: workflowFolder,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            ) {
                while let fileURL = enumerator.nextObject() as? URL {
                    let ext = fileURL.pathExtension.lowercased()
                    if ext == Constants.FileExtensions.pdf {
                        pdfs.append(fileURL)
                    } else if ext == Constants.FileExtensions.indd {
                        indds.append(fileURL)
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
                if fileName.calculateSimilarity(with: existingName) > Constants.similarityThreshold {
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
                    
                    if fileExtension == Constants.FileExtensions.pdf {
                        // Csak akkor adjuk hozzá, ha nincs hasonló nevű
                        if !isNameTooSimilar(fileName, to: pdfs) {
                            pdfs.append(fileURL)
                        }
                    } else if fileExtension == Constants.FileExtensions.indd {
                        // Csak akkor adjuk hozzá, ha nincs hasonló nevű
                        if !isNameTooSimilar(fileName, to: indds) {
                            indds.append(fileURL)
                        }
                    }
                }
            }
        }
        
        self.availablePDFs = pdfs
        self.availableInddFiles = indds
    }
}
