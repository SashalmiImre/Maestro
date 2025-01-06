import SwiftUI
import PDFKit

struct LayoutView: View {
    // Properties remain the same until PageView
    
    @EnvironmentObject var manager: PublicationManager
    
    let layout: Layout
    
    // MARK: - Computed Properties
    
    /// A tényleges maximum oldalszám (felhasználói vagy számított
//    private var effectiveMaxPageNumber: Int {
//        userDefinedMaxPage ?? max(
//            self.layout.pages.map(\.pageNumber).max() ?? 0,
//            self.layout.pageCount
//        )
//    }
    
    /// Kiszámítja az alapértelmezett oldalméretet a layout alapján
    //    private var defaultPageSize: CGSize {
    //        if let firstPage = layout.pages.first?.pdfDocument.page(at: 0) {
    //            let bounds = firstPage.bounds(for: .trimBox)
    //            return CGSize(width: bounds.width, height: bounds.height)
    //        }
    //        return CGSize(width: 595, height: 842)  // A4 alapértelmezett méret
    //    }
    
    //    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 200), count: 5)
    
    //    private func createPagePairView(for pair: PagePair) -> some View {
    //        PagePairView(pagePair: pair,
    //            scale: pdfScale,
    //            isEditMode: isEditMode
    //        )
    //    }
//    private func exportCurrentView() async {
    //        guard let publication = manager.publication else { return }
    //
    //        // Kiszámoljuk a teljes méreteket
    //        let spacing = 100.0 * pdfScale
    //        let rowCount = Int(ceil(Double(layout.pagePairs(coverage: 1...effectiveMaxPageNumber).count) / 5))
    //        let pairWidth = defaultPageSize.width * pdfScale * 2
    //        let pairHeight = defaultPageSize.height * pdfScale
    //
    //        // A teljes méret az összes sorral, spacing-gel és padding-gal
    //        let totalWidth = spacing + (pairWidth + spacing) * 5 + spacing
    //        let totalHeight = spacing + (pairHeight + spacing + 20 * pdfScale) * CGFloat(rowCount) + spacing // Extra hely az oldalszámoknak
    //
    //        // Létrehozunk egy megfelelő méretű képet
    //        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight))
    //        image.lockFocus()
    //
    //        // Fehér háttér
    //        NSColor.white.setFill()
    //        NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight).fill()
    //
    //        // Kirajzoljuk az összes oldalpárt
    //        for (index, pair) in layout.pagePairs(coverage: 1...effectiveMaxPageNumber).enumerated() {
    //            let row = index / 5
    //            let col = index % 5
    //
    //            let x = spacing + CGFloat(col) * (pairWidth + spacing)
    //            let y = totalHeight - spacing - (CGFloat(row + 1) * (pairHeight + spacing + 20 * pdfScale))
    //
    //            // Oldalpár fekete kerete
    //            let pairRect = NSRect(
    //                x: x,
    //                y: y,
    //                width: pairWidth,
    //                height: pairHeight
    //            )
    //            NSColor.black.withAlphaComponent(0.3).setStroke()
    //            let borderPath = NSBezierPath(rect: pairRect)
    //            borderPath.lineWidth = 0.5 * pdfScale
    //            borderPath.stroke()
    //
    //            // Oldalszámok kirajzolása
    //            drawPageNumbers(
    //                leftNumber: pair.leftNumber,
    //                rightNumber: pair.rightNumber,
    //                x: x,
    //                y: y,
    //                pairWidth: pairWidth
    //            )
    //
    //            // Bal oldal
    //            let leftRect = NSRect(
    //                x: x,
    //                y: y,
    //                width: defaultPageSize.width * pdfScale,
    //                height: pairHeight
    //            )
    //
    //            if let leftPage = pair.left?.pdfDocument.page(at: 0) {
    //                NSGraphicsContext.current?.cgContext.saveGState()
    //                NSGraphicsContext.current?.cgContext.translateBy(x: x, y: y)
    //                NSGraphicsContext.current?.cgContext.scaleBy(x: pdfScale, y: pdfScale)
    //                leftPage.draw(with: .trimBox, to: NSGraphicsContext.current!.cgContext)
    //                NSGraphicsContext.current?.cgContext.restoreGState()
    //
    //                // Piros keret ha kell
    //                drawRedBorder(at: leftRect,
    //                             isPDFFromWorkflow: pair.left?.pdfSource.isSubfolder(of: publication.pdfFolder) ?? true)
    //            } else if pair.leftNumber > 0 && pair.leftNumber <= effectiveMaxPageNumber {
    //                NSColor.gray.withAlphaComponent(0.1).setFill()
    //                leftRect.fill()
    //                drawPageNumber(pair.leftNumber, at: leftRect)
    //            }
    //
    //            // Jobb oldal
    //            let rightRect = NSRect(
    //                x: x + defaultPageSize.width * pdfScale,
    //                y: y,
    //                width: defaultPageSize.width * pdfScale,
    //                height: pairHeight
    //            )
    //
    //
    //            if let rightPage = pair.right?.pdfDocument.page(at: 0) {
    //                NSGraphicsContext.current?.cgContext.saveGState()
    //                NSGraphicsContext.current?.cgContext.translateBy(x: x + defaultPageSize.width * pdfScale, y: y)
    //                NSGraphicsContext.current?.cgContext.scaleBy(x: pdfScale, y: pdfScale)
    //                rightPage.draw(with: .trimBox, to: NSGraphicsContext.current!.cgContext)
    //                NSGraphicsContext.current?.cgContext.restoreGState()
    //
    //                // Piros keret ha kell
    //                drawRedBorder(at: rightRect,
    //                             isPDFFromWorkflow: pair.right?.pdfSource.isSubfolder(of: publication.pdfFolder) ?? true)
    //            } else if pair.rightNumber > 0 && pair.rightNumber <= effectiveMaxPageNumber {
    //                NSColor.gray.withAlphaComponent(0.1).setFill()
    //                NSColor.gray.withAlphaComponent(0.1).setFill()
    //                rightRect.fill()
    //                drawPageNumber(pair.rightNumber, at: rightRect)
    //            }
    //        }
    //
    //        image.unlockFocus()
    //
    //        // JPG fájl mentése
    //        // TODO: fájlelnevezés rendbetétele
    //        let fileName = "\(manager.publication!.name) –  layout"
    //        let fileURL = publication.baseFolder.appendingPathComponent(fileName).appendingPathExtension("jpg")
    //
    //        if let imageData = image.tiffRepresentation,
    //           let bitmap = NSBitmapImageRep(data: imageData),
    //           let jpgData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) {
    //            try? jpgData.write(to: fileURL)
    //            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    //        }
    //    }
    //
    //    /// Rajzol egy nagyméretű oldalszámot a megadott helyre
    //    private func drawPageNumber(_ number: Int, at rect: NSRect) {
    //        let text = NSString(string: String(number))
    //        let font = NSFont.systemFont(ofSize: 60 * pdfScale)
    //        let attributes: [NSAttributedString.Key: Any] = [
    //            .font: font,
    //            .foregroundColor: NSColor.gray.withAlphaComponent(0.3)
    //        ]
    //
    //        let size = text.size(withAttributes: attributes)
    //        let x = rect.minX + (rect.width - size.width) / 2
    //        let y = rect.minY + (rect.height - size.height) / 2
    //
    //        text.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
    //    }
    //
    //    /// Rajzol egy piros keretet a megadott területre
    //    private func drawRedBorder(at rect: NSRect, isPDFFromWorkflow: Bool = false) {
    //        if !isPDFFromWorkflow {
    //            NSColor.red.setStroke()
    //            let path = NSBezierPath(rect: rect)
    //            path.lineWidth = 2.0 * pdfScale
    //            path.stroke()
    //        }
    //    }
    
    // MARK: - Layout Properties
    
    private var spacing: CGFloat {
        80 * manager.zoomLevel
    }
    
    private var columns: [GridItem] {
        let pageWidth = manager.layouts.first!.maxPageSize(for: .trimBox).width
        let scaledWidth = pageWidth * manager.zoomLevel
        let pairWidth = scaledWidth * 2
        
        return Array(repeating: .init(.fixed(pairWidth), spacing: spacing), count: 5)
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVGrid(columns: columns, spacing: spacing) {
                ForEach(layout.pagePairs(maxPageCount: manager.maxPageNumber), id: \.self) { pagePair in
                    PagePairView(pagePair: pagePair)
                }
            }
            .padding(spacing)
            .contentShape(Rectangle())
            .onTapGesture {
                // clearSelection()
            }
            .onChange(of: manager.isEditMode) { _, newValue in
                if !newValue {
                    // clearSelection()
                }
            }
        }
    }
}
