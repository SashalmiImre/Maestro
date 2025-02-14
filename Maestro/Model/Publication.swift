import Foundation
import PDFKit

/// Egy teljes kiadvány reprezentációja, amely kezeli a cikkeket és a munkafolyamat mappákat
/// - Note: A @MainActor attribútum biztosítja, hogy az osztály csak a fő szálon fusson
actor Publication {
    // MARK: - Konstansok
    
    /// A kiadvány neve (a mappa neve alapján)
    let name: String
    
    /// A kiadványhoz tartozó cikkek listája
    var articles: Array<Article> = .init()
    
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
    
    
    // MARK: - Initialization
    
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
    
    
    // MARK: - Articles

    func refreshArticles() async {
        guard let fileURLs = try? await findFiles() else { return }
        print("refreshArticles")
        var newArticles: Array<Article> = []
        
        await withTaskGroup(of: Article?.self) { group in
            for inddFileURL in fileURLs.indd {
                group.addTask {
                    return await Article(publication: self,
                                         inddFile: inddFileURL,
                                         availablePDFs: fileURLs.pdf)
                }
            }
            
            for await article in group {
                if let article = article {
                    newArticles.append(article)
                }
            }
        }
        
        self.articles = newArticles
    }
    
    
    typealias workingFileURLs = (indd: Array<URL>, pdf: Array<URL>)
    private func findFiles() async throws -> workingFileURLs {
        
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
        
        return (indd: inddURLs, pdf: pdfURLs)
    }
    
    
    private func findValidSubfolders() throws -> [URL] {
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
    
    
    // MARK: - Layouts

    var layoutCombinations: Set<Layout> {
         get async {
            // Guard és ellenőrzések maradnak ugyanazok a publikációra
            guard !articles.isEmpty else {
                return .init()
            }
            
            // Szétválasztjuk a cikkeket ütközők és nem ütközők csoportjára
            let (nonConflictingArticles, conflictingArticles) = findArticleCoverageConflicts()
            
            // Létrehozzuk az alap layout-ot a nem ütköző cikkekkel
            let baseLayout = Layout(publication: self)
            for article in nonConflictingArticles {
                await baseLayout.add(article)
            }
            
            // Ha nincs ütköző cikk, nincs szükség további variációk generálására
            if conflictingArticles.isEmpty {
                return [baseLayout]
            }
            
            // Csoportosítja a cikkeket oldalszám átfedés alapján
            let conflictGroups = groupArticles(conflictingArticles)
            let combinations = generateArticleCombinations(conflictGroups)
            
            var allLayouts = Set<Layout>()
            
            // Az ütköző cikkek minden lehetséges sorrendjét kipróbáljuk
            // Minden taskhoz hozzon létre egy izolált baseLayout másolatot
             let baseLayoutCopy = Layout(publication: baseLayout.publication,
                                         articles: baseLayout.articles)
            
            await withTaskGroup(of: Layout?.self) { group in
                for combination in combinations {
                    group.addTask { [combination] in
                        let layout = Layout(publication: baseLayoutCopy.publication,
                                            articles: baseLayoutCopy.articles)
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
            
            return allLayouts
        }
    }
    
    
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
    
    
    private func generateArticleCombinations(_ groups: Array<Array<Article>>) -> Array<Array<Article>> {
        
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
    

    typealias ArticleCoverageConflictResult = (nonConflicting: Array<Article>, conflicting: Array<Article>)
    private func findArticleCoverageConflicts() -> ArticleCoverageConflictResult {
        
        var nonConflicting: Array<Article> = []
        var conflicting: Array<Article> = []
        
        for article in articles {
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
}
