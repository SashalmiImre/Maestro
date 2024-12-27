import Foundation
import PDFKit

/// Egy teljes kiadvány reprezentációja, amely kezeli a cikkeket és a munkafolyamat mappákat
/// - Note: A @MainActor attribútum biztosítja, hogy az osztály csak a fő szálon fusson
@MainActor
class Publication: ObservableObject {
    // MARK: - Konstansok
    
    /// A kiadvány neve (a mappa neve alapján)
    let name: String
    
    /// A kiadványhoz tartozó cikkek listája
    @Published var articles: [Article] = .init()
    
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
    
    /// Exportálja a megadott layout-ot JPG formátumba
    /// - Parameters:
    ///   - layout: Az exportálandó layout
    ///   - title: Az exportált fájl neve
    ///   - scale: A renderelés méretezése
    /// - Returns: Az exportált fájl URL-je, vagy nil hiba esetén
    func exportToJPG(layout: Layout, title: String? = nil, scale: CGFloat = 1.0) -> URL? {
        guard let firstPage = layout.pages.first?.pdfDocument.page(at: 0) else { return nil }
        
        // Alapméret kiszámítása az első oldal alapján
        let baseSize = firstPage.bounds(for: .trimBox).size
        
        // A teljes kép mérete (5 oldalpár per sor)
        let pairWidth = baseSize.width * 2 * scale
        let pairHeight = baseSize.height * scale
        let spacing = 20.0 * scale
        
        let rowCount = Int(ceil(Double(layout.pages.count) / 10.0))
        let totalWidth = (pairWidth + spacing) * 5
        let totalHeight = (pairHeight + spacing) * CGFloat(rowCount)
        
        // NSImage létrehozása
        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight))
        
        image.lockFocus()
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight).fill()
        
        // Oldalak rendezése párokba
        var pairs: [(left: Layout.Page?, right: Layout.Page?)] = []
        var currentPair: (left: Layout.Page?, right: Layout.Page?) = (nil, nil)
        
        for page in layout.pages.sorted(by: { $0.pageNumber < $1.pageNumber }) {
            if page.pageNumber % 2 == 0 {
                currentPair.left = page
                pairs.append(currentPair)
                currentPair = (nil, nil)
            } else {
                currentPair.right = page
            }
        }
        if currentPair.left != nil || currentPair.right != nil {
            pairs.append(currentPair)
        }
        
        // Oldalak kirajzolása
        for (index, pair) in pairs.enumerated() {
            let row = index / 5
            let col = index % 5
            
            let x = CGFloat(col) * (pairWidth + spacing)
            let y = totalHeight - (CGFloat(row + 1) * (pairHeight + spacing))
            
            // Bal oldal
            if let leftPage = pair.left?.pdfDocument.page(at: 0) {
                let leftRect = NSRect(x: x, y: y, width: baseSize.width * scale, height: pairHeight)
                if let context = NSGraphicsContext.current?.cgContext {
                    context.saveGState()
                    context.scaleBy(x: scale, y: scale)
                    leftPage.draw(with: .trimBox, to: context)
                    context.restoreGState()
                }
            }
            
            // Jobb oldal
            if let rightPage = pair.right?.pdfDocument.page(at: 0) {
                let rightRect = NSRect(x: x + baseSize.width * scale, y: y, width: baseSize.width * scale, height: pairHeight)
                if let context = NSGraphicsContext.current?.cgContext {
                    context.saveGState()
                    context.scaleBy(x: scale, y: scale)
                    rightPage.draw(with: .trimBox, to: context)
                    context.restoreGState()
                }
            }
        }
        
        image.unlockFocus()
        
        // JPG fájl létrehozása
        let fileName = title ?? "layout_\(Date().timeIntervalSince1970)"
        let fileURL = baseFolder.appendingPathComponent(fileName).appendingPathExtension("jpg")
        
        if let imageData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: imageData),
           let jpgData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.9]) {
            try? jpgData.write(to: fileURL)
            return fileURL
        }
        
        return nil
    }
    
    // Rest of the implementation remains the same
}
