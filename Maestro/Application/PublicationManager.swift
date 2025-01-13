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
    
    @Published var publication: Publication?
    @Published private(set) var layouts: Set<Layout> = .init()
    @Published var selectedLayoutIndex: Int = 0
    @Published var maxPageNumber: Int = 8
    @Published var zoomLevel: Double = ZoomSettings.initial
    @Published var isEditMode: Bool = false
    @Published var isExporting = false
    @Published var layoutColumns: Int = 5
    @Published var currentPageNumber: Int = 1
    

    // MARK: - Private Properties
    
    private var availablePDFs: [URL] = []
    private var availableInddFiles: [URL] = []
    
    // MARK: - Initialization
    
    /// Inicializálja az állapotkezelőt és legenerálja az első layout-okat
    init() {
        Task {
            await refresh()
        }
    }
    
    
    // MARK: - Computed properties
    
    /// A maximális oldalszám, ami befogadja az összes oldalt és osztható 8-cal,
    /// plusz 4 oldal a borítóhoz
    /// - Returns: A legkisebb 8-cal osztható szám (a belső oldalakra), ami nagyobb vagy egyenlő
    /// mint a pageCount, plusz 4 oldal a borítóhoz
    var printingPageCount: Int {
        let coverPageCount = 4
        let pageCount = (selectedLayout?.maxPageNumber ?? 8) - coverPageCount
        let remainder = pageCount % 8
        let innerPages = remainder == 0 ? pageCount : pageCount + (8 - remainder)
        return innerPages + coverPageCount
    }
    
    var selectedLayout: Layout? {
        Array(layouts)[safe: selectedLayoutIndex]
    }
    
    
    // MARK: - Refresh/reset

    private func reset() {
        layouts.removeAll()
        selectedLayoutIndex = 0
        publication?.articles.removeAll()
        availablePDFs = []
        availableInddFiles = []
        maxPageNumber = 8
    }
    
    func refresh() async {
        reset()
        await refreshArticles()
        await generateLayoutCombinations()
        maxPageNumber = printingPageCount
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
                    return await Article(publication: self.publication!, inddFile: inddFile, availablePDFs: pdfs)
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
    
    /// Csoportosítja a cikkeket oldalszám átfedés alapján
    private func groupConflictingArticles(_ articles: Array<Article>)
    -> Array<Array<Article>> {
        
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
    private func generateArticleCombinations(from groups: Array<Array<Article>>)
    -> Array<Array<Article>> {
        
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
    private func findArticleConflicts(_ articles: [Article])
    -> (nonConflicting: [Article], conflicting: [Article]) {
        
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
    
    
    // MARK: - Layouts

    /// Generálja a lehetséges layout variációkat a publikáció cikkeiből
    /// A függvény figyelembe veszi az oldalszám-ütközéseket és optimalizál a cache használatával
    ///
    /// - Returns: A lehetséges layout-ok tömbje
    private func generateLayoutCombinations() async {
        // Guard és ellenőrzések maradnak ugyanazok a publikációra
        guard let publication = publication,
              !publication.articles.isEmpty else {
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
            self.layouts = [baseLayout]
            return
        }
        
        // Csoportosítja a cikkeket oldalszám átfedés alapján
        let conflictGroups = groupConflictingArticles(conflictingArticles)
        let combinations = generateArticleCombinations(from: conflictGroups)
        
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
        self.selectedLayoutIndex = 0
    }
    
    
    // MARK: - Filesystem operations
    
    /// Megkeresi az összes PDF és InDesign fájlt, először a workflow mappákban,
    /// majd a többi mappában, de csak a nem hasonló nevűeket
    private func findAllFiles() async throws {
        guard publication != nil else { return }
        
        let propertiesKeys: Array<URLResourceKey> = [.isRegularFileKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        
        availablePDFs      = .init()
        availableInddFiles = .init()
        let workfolders = self.publication!.workflowFolders
        
        // Process workflow folders in parallel
        await withTaskGroup(of: (Array<URL>, Array<URL>).self) { group in
            for workflowFolder in workfolders {
                group.addTask {
                    var pdfs:  Array<URL> = .init()
                    var indds: Array<URL> = .init()
                    
                    if let enumerator = FileManager.default.enumerator(
                        at: workflowFolder,
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
                self.availablePDFs.append(contentsOf: pdfs)
                self.availableInddFiles.append(contentsOf: indds)
            }
        }
        
        // Process other folders
        let otherFolders     = try findValidSubfolders()
        let currentPDFs      = self.availablePDFs
        let currentInddFiles = self.availableInddFiles
        
        await withTaskGroup(of: (Array<URL>, Array<URL>).self) { group in
            for otherFolder in otherFolders {
                group.addTask {
                    var pdfs:  Array<URL> = .init()
                    var indds: Array<URL> = .init()
                    
                    if let enumerator = FileManager.default.enumerator(
                        at: otherFolder,
                        includingPropertiesForKeys: propertiesKeys,
                        options: options
                    ) {
                        while let fileURL = enumerator.nextObject() as? URL {
                            let fileName = fileURL.deletingPathExtension().lastPathComponent
                            let fileExtension = fileURL.pathExtension.lowercased()
                            
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
    
    // MARK: - Zoom constans

    struct ZoomSettings {
        static let range = 0.1...2.1
        static let step = 0.2
        static let initial = 0.3
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
