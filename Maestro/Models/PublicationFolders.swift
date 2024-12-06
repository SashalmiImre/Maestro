import Foundation

struct PublicationFolders {
    let baseFolder: URL
    let layoutFolder: URL
    let correctedFolder: URL
    let printableFolder: URL
    let printedFolder: URL
    
    init(baseFolder: URL) throws {
        self.baseFolder = baseFolder
        
        // Fix almappák létrehozása
        self.layoutFolder = baseFolder.appendingPathComponent("__Tordelve")
        self.correctedFolder = layoutFolder.appendingPathComponent("__Olvasva")
        self.printableFolder = correctedFolder.appendingPathComponent("__Levilagithato")
        self.printedFolder = correctedFolder.appendingPathComponent("__Levil")
        
        // Létrehozzuk a hiányzó mappákat
        let fileManager = FileManager.default
        
        if !fileManager.fileExists(atPath: layoutFolder.path) {
            try fileManager.createDirectory(at: layoutFolder, withIntermediateDirectories: true)
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
    }
    
    /// Visszaadja az összes rendszermappát
    var systemFolders: [URL] {
        [baseFolder, layoutFolder, correctedFolder, printableFolder, printedFolder]
    }
    
    /// Megkeresi az érvényes almappákat a base mappában
    func findValidSubfolders() throws -> [URL] {
        let contents = try FileManager.default.contentsOfDirectory(
            at: baseFolder,
            includingPropertiesForKeys: [.isDirectoryKey, .isHiddenKey, .tagNamesKey],
            options: .skipsHiddenFiles
        )
        
        let nemKellPattern = #"^(?i)nemkell$"#
        
        let validSubfolders = try contents.filter { folderURL in
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
            
            return isDirectory && !isHidden && !hasGrayTag && !isNemKell
        }
        
        // Hozzáadjuk a rendszermappákat is
        return validSubfolders + systemFolders
    }
} 