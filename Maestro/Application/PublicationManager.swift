//
//  PublicationManager.swift
//  Maestro
//
//  Created by Sashalmi Imre on 21/12/2024.
//

import SwiftUI
import Algorithms

/// Az alkalmazás állapotkezelője, amely felelős a kiadvány és annak lehetséges
/// oldalelrendezéseinek kezeléséért.
@MainActor
class PublicationManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Az aktuálisan betöltött kiadvány
    @Published var publication: Publication?
    
    /// A kiadvány lehetséges oldalelrendezései
    /// Csak olvasható kívülről, a generateLayouts() függvény frissíti
    @Published private(set) var layouts: Set<Layout>?
    @Published var selectedLayoutIndex = 0

    // MARK: - Private Properties
    
    /// Cache a már kiszámolt layout-oknak
    /// A kulcs egy egyedi string azonosító, ami a cikkek neveiből és oldalszámaiból áll
//    private      var layoutCache: [String: [Layout]] = [:]
//    private      var lastGeneratedKey: String? = nil
    
    private(set) var availablePDFs: [URL] = []
    private(set) var availableInddFiles: [URL] = []
    
    // MARK: - Initialization
    
    /// Inicializálja az állapotkezelőt és legenerálja az első layout-okat
    init() {
        Task {
            await refreshLayouts()
        }
    }
    
    // MARK: - Layouts

    func refreshLayouts() async {
        // Reset everything
        layouts = nil
        availablePDFs = []
        availableInddFiles = []
        selectedLayoutIndex = 0
        publication?.articles.removeAll()  // Clear existing articles
        await refreshArticles()
        await generateLayouts()
    }
    
    /// Generálja a lehetséges layout variációkat a publikáció cikkeiből
    /// A függvény figyelembe veszi az oldalszám-ütközéseket és optimalizál a cache használatával
    ///
    /// - Returns: A lehetséges layout-ok tömbje
    private func generateLayouts() async {
        // Guard és ellenőrzések maradnak ugyanazok a publikációra
        guard let publication = publication,
              !publication.articles.isEmpty else {
            self.layouts = .init()
            return
        }
        
        // Szétválasztjuk a cikkeket ütközők és nem ütközők csoportjára
        let (nonConflictingArticles, conflictingArticles) = findArticleConflicts(publication.articles)
        
        // Létrehozzuk az alap layout-ot a nem ütköző cikkekkel
        var baseLayout = Layout()
        for article in nonConflictingArticles {
            baseLayout.add(article)
        }
        
        // Ha nincs ütköző cikk, nincs szükség további variációk generálására
        if conflictingArticles.isEmpty {
            self.layouts = Set([baseLayout])
            return
        }
        
        // Csoportosítja a cikkeket oldalszám átfedés alapján
        let conflictGroups = groupConflictingArticles(conflictingArticles)
        let combinations = generateCombinations(from: conflictGroups)
        
        var allLayouts = Set<Layout>()
        
        // Az ütköző cikkek minden lehetséges sorrendjét kipróbáljuk
        await withTaskGroup(of: Layout?.self) { group in
            for combination in combinations {
                group.addTask {
                    var layout = baseLayout
                    for article in combination {
                        if !layout.add(article) {
                            return nil
                        }
                    }
                    return layout
                }
            }
            
            // Összegyűjtjük az érvényes layout-okat
            for await layout in group {
                if let layout = layout {
                    allLayouts.insert(layout)
                }
            }
        }
        
        // Ha nem sikerült egyetlen layout-ot sem generálni, használjuk az alapot
        if allLayouts.isEmpty {
            allLayouts.insert(baseLayout)
        }
        
        self.layouts = allLayouts
    }
    
    /// Csoportosítja a cikkeket oldalszám átfedés alapján
    private func groupConflictingArticles(_ articles: [Article]) -> [[Article]] {
        var groups: [[Article]] = []
        var remainingArticles = articles
        
        while !remainingArticles.isEmpty {
            let article = remainingArticles.removeFirst()
            var group = [article]
            
            // Megkeressük az összes cikket, ami átfed a csoport bármelyik cikkével
            var i = 0
            while i < remainingArticles.count {
                if group.contains(where: { remainingArticles[i].overlaps(with: $0) }) {
                    group.append(remainingArticles.remove(at: i))
                } else {
                    i += 1
                }
            }
            
            groups.append(group)
        }
        
        return groups
    }
    
    /// Generálja az összes lehetséges kombinációt a cikkcsoportokból
    private func generateCombinations(from groups: [[Article]]) -> [[Article]] {
        // Ha nincs csoport, üres tömböt adunk vissza
        guard !groups.isEmpty else { return [[]] }
        
        // Használjuk a cartesianProduct függvényt a Swift Algorithms-ból
        return groups.reduce([[]]) { result, group in
            result.flatMap { combination in
                group.map { article in
                    combination + [article]
                }
            }
        }
    }
    
    /// Szétválasztja a cikkeket ütkö és nem ütköző csoportokra
    /// Egy cikk akkor ütközik, ha van olyan másik cikk, amellyel átfedésben van az oldalszámozása
    ///
    /// - Parameter articles: A vizsgálandó cikkek tömbje
    /// - Returns: Tuple, ami tartalmazza a nem ütköző és ütköző cikkek tömbjeit
    private func findArticleConflicts(_ articles: [Article]) -> (nonConflicting: [Article], conflicting: [Article]) {
        var nonConflicting: [Article] = []
        var conflicting: [Article] = []
        
        for article in articles {
            // Ellenőrizzük, hogy a cikk ütközik-e bármely másik cikkel
            let hasConflict = articles
                .filter { $0.name != article.name } // Kihagyjuk önmagát
                .contains { article.overlaps(with: $0) }
            
            // Az eredmény alapján kategorizáljuk a cikket
            if hasConflict {
                conflicting.append(article)
            } else {
                nonConflicting.append(article)
            }
        }
        
        return (nonConflicting, conflicting)
    }
    
    
    // MARK: - Articles
    
    private func refreshArticles() async {
        // Find all files asynchronously
        try? await findAllFiles()
        
        let pdfs = self.availablePDFs
        let inddFiles = self.availableInddFiles
        
        var newArticles: [Article] = []  // Temporary array for new articles
        
        // Process articles in parallel
        await withTaskGroup(of: Article?.self) { group in
            for inddFile in inddFiles {
                group.addTask {
                    return Article(inddFile: inddFile, availablePDFs: pdfs)
                }
            }
            
            for await article in group {
                if let article = article {
                    newArticles.append(article)  // Collect new articles
                }
            }
        }
        
        // Set all articles at once
        self.publication?.articles = newArticles
    }
    
    /// Megkeresi az első szintű érvényes almappákat a base mappában (workflow mappák nélkül)
    private func findValidSubfolders() throws -> [URL] {
        if publication == nil { return .init() }
        
        // Csak az első szintű tartalom lekérése (nem rekurzív)
        let contents = try FileManager.default.contentsOfDirectory(
            at: publication!.baseFolder,
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
            let startsWithUnderscore = folderURL.lastPathComponent.hasPrefix("_")
            
            return isDirectory && !isHidden && !hasGrayTag && !isNemKell && !startsWithUnderscore
        }
    }
    
    /// Megkeresi az összes PDF és InDesign fájlt, először a workflow mappákban,
    /// majd a többi mappában, de csak a nem hasonló nevűeket
    private func findAllFiles() async throws {
        if publication == nil { return }

        availablePDFs = []
        availableInddFiles = []
        let workfolders = self.publication!.workflowFolders
        
        // Process workflow folders in parallel
        await withTaskGroup(of: ([URL], [URL]).self) { group in
            for workflowFolder in workfolders {
                group.addTask {
                    var pdfs: [URL] = []
                    var indds: [URL] = []
                    
                    if let enumerator = FileManager.default.enumerator(
                        at: workflowFolder,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                    ) {
                        while let fileURL = enumerator.nextObject() as? URL {
                            let ext = fileURL.pathExtension.lowercased()
                            if ext == "pdf" {
                                pdfs.append(fileURL)
                            } else if ext == "indd" {
                                indds.append(fileURL)
                            }
                        }
                    }
                    return (pdfs, indds)
                }
            }
            
            for await (pdfs, indds) in group {
                self.availablePDFs.append(contentsOf: pdfs)
                self.availableInddFiles.append(contentsOf: indds)
            }
        }
        
        // Process other folders
        let otherFolders = try findValidSubfolders()
        let currentPDFs = self.availablePDFs
        let currentInddFiles = self.availableInddFiles
        
        await withTaskGroup(of: ([URL], [URL]).self) { group in
            for otherFolder in otherFolders {
                group.addTask {
                    var pdfs: [URL] = []
                    var indds: [URL] = []
                    
                    if let enumerator = FileManager.default.enumerator(
                        at: otherFolder,
                        includingPropertiesForKeys: [.isRegularFileKey],
                        options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
                    ) {
                        while let fileURL = enumerator.nextObject() as? URL {
                            let fileExtension = fileURL.pathExtension.lowercased()
                            let fileName = fileURL.deletingPathExtension().lastPathComponent
                            
                            if fileExtension == "pdf" && !NameUtils.isNameTooSimilar(fileName, to: currentPDFs) {
                                pdfs.append(fileURL)
                            } else if fileExtension == "indd" && !NameUtils.isNameTooSimilar(fileName, to: currentInddFiles) {
                                indds.append(fileURL)
                            }
                        }
                    }
                    return (pdfs, indds)
                }
            }
            
            for await (pdfs, indds) in group {
                self.availablePDFs.append(contentsOf: pdfs)
                self.availableInddFiles.append(contentsOf: indds)
            }
        }
    }
}
