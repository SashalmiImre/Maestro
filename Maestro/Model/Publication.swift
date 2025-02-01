import Foundation
import PDFKit

/// Egy teljes kiadvány reprezentációja, amely kezeli a cikkeket és a munkafolyamat mappákat
/// - Note: A @MainActor attribútum biztosítja, hogy az osztály csak a fő szálon fusson
actor Publication {
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
    
    /// Az oldalakból generált layoutok
    private(set) var layouts: Set<Layout> = .init()
    
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
    
    func refreshArticles() async {
        // Find all files asynchronously
        guard let fileURLs = try? await findFiles() else { return }
        
        var newArticles: [Article] = []
        
        await withTaskGroup(of: Article?.self) { group in
            for inddFile in fileURLs.inddURLs {
                group.addTask {
                    return await Article(publication: self,
                                         inddFile: inddFile,
                                         availablePDFs: fileURLs.pdfURLs)
                }
            }
            
            for await article in group {
                if let article = article {
                    newArticles.append(article)  // Collect new articles
                }
            }
        }
        
        self.articles = newArticles
    }
    
    /// Megkeresi az összes PDF és InDesign fájlt, először a workflow mappákban,
    /// majd a többi mappában, de csak a nem hasonló nevűeket
    private func findFiles() async throws -> (inddURLs: [URL], pdfURLs: [URL]) {
        
        let propertiesKeys: Array<URLResourceKey> = [.isRegularFileKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        var inddURLs: Array<URL> = .init()
        var pdfURLs: Array<URL> = .init()
        
        let otherSubfolders = try findValidSubfolders()
        let foldersToCheck  = workflowFolders + otherSubfolders
        
        // Process workflow folders in parallel
        await withTaskGroup(of: (Array<URL>, Array<URL>).self) { group in
            for folder in foldersToCheck {
                group.addTask {
                    var pdfs:  Array<URL> = .init()
                    var indds: Array<URL> = .init()
                    
                    if let enumerator = FileManager.default.enumerator(
                        at: folder,
                        includingPropertiesForKeys: propertiesKeys,
                        options: options
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
                pdfURLs.append(contentsOf: pdfs)
                inddURLs.append(contentsOf: indds)
            }
        }
        
        return (inddURLs: inddURLs, pdfURLs: pdfURLs)
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
            let startsWithUnderscore = folderURL.lastPathComponent.hasPrefix("_")
            
            return isDirectory && !isHidden && !hasGrayTag && !isNemKell && !startsWithUnderscore
        }
    }
    
    
    /// Csoportosítja a cikkeket oldalszám átfedés alapján
    private func groupArticles(_ articles: Array<Article>) -> Array<Array<Article>> {
        
        var groups: Array<Array<Article>> = .init()
        var remainingArticles = articles
        
        while !remainingArticles.isEmpty {
            let article = remainingArticles.removeFirst()
            var group = [article]
            
            // Megkeressük az összes cikket, ami átfed a csoport bármelyik cikkével
            var i = 0
            while i < remainingArticles.count {
                if group.contains(where: {
                    remainingArticles[i].coverage.overlaps($0.coverage)
                }) {
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
    private func generateArticleCombinations(_ groups: Array<Array<Article>>) -> Array<Array<Article>> {
        
        // Ha nincs csoport, üres tömböt adunk vissza
        guard !groups.isEmpty else { return .init() }
        
        // Ha csak egy csoport van, visszaadjuk annak elemeit külön-külön tömbökben
        if groups.count == 1 {
            return groups[0].map { [$0] }
        }
        
        // Kezdeti eredmény az első csoport elemeiből
        var result = groups[0].map { [$0] }
        
        // A többi csoportot egyesével kombináljuk az eddigi eredménnyel
        for group in groups.dropFirst() {
            result = result.flatMap { combination in
                group.map { article in
                    combination + [article]
                }
            }
        }
        
        return result
    }
    
    /// Szétválasztja a cikkeket ütköző és nem ütköző csoportokra
    /// Egy cikk akkor ütközik, ha van olyan másik cikk, amellyel átfedésben van az oldalszámozása
    ///
    /// - Parameter articles: A vizsgálandó cikkek tömbje
    /// - Returns: Tuple, ami tartalmazza a nem ütköző és ütköző cikkek tömbjeit
    private func findArticleConflicts()
    -> (nonConflicting: [Article], conflicting: [Article]) {
        
        var nonConflicting: [Article] = []
        var conflicting: [Article] = []
        
        for article in articles {
            // Ellenőrizzük, hogy a cikk ütközik-e bármely másik cikkel
            let hasConflict = articles
                .filter { $0.name != article.name } // Kihagyjuk önmagát
                .contains { article.coverage.overlaps($0.coverage) }
            
            // Az eredmény alapján kategorizáljuk a cikket
            if hasConflict {
                conflicting.append(article)
            } else {
                nonConflicting.append(article)
            }
        }
        
        return (nonConflicting, conflicting)
    }
    
    
    // MARK: - Layouts

    /// Generálja a lehetséges layout variációkat a publikáció cikkeiből
    /// A függvény figyelembe veszi az oldalszám-ütközéseket és optimalizál a cache használatával
    ///
    /// - Returns: A lehetséges layout-ok tömbje
    private func generateLayoutCombinations() async {
        // Guard és ellenőrzések maradnak ugyanazok a publikációra
        guard !articles.isEmpty else {
            return
        }
        
        // Szétválasztjuk a cikkeket ütközők és nem ütközők csoportjára
        let (nonConflictingArticles, conflictingArticles) = findArticleConflicts()
        
        // Létrehozzuk az alap layout-ot a nem ütköző cikkekkel
        var baseLayout = Layout(publication: self)
        for article in nonConflictingArticles {
            await baseLayout.add(article)
        }
        
        // Ha nincs ütköző cikk, nincs szükség további variációk generálására
        if conflictingArticles.isEmpty {
            self.layouts = [baseLayout]
            return
        }
        
        // Csoportosítja a cikkeket oldalszám átfedés alapján
        let conflictGroups = groupArticles(conflictingArticles)
        let combinations = generateArticleCombinations(conflictGroups)
        
        var allLayouts = Set<Layout>()
        
        // Az ütköző cikkek minden lehetséges sorrendjét kipróbáljuk
        // Minden taskhoz hozzon létre egy izolált baseLayout másolatot
        let baseLayoutCopy = baseLayout
        
        await withTaskGroup(of: Layout?.self) { group in
            for combination in combinations {
                group.addTask { [combination] in
                    var layout = baseLayoutCopy
                    for article in combination {
                        if await !layout.add(article) {
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
}
