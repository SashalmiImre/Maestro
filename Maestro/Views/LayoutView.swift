import SwiftUI
import PDFKit

struct LayoutView: View {
    // Properties remain the same until PageView
    
    @EnvironmentObject var manager: PublicationManager
    
    let layout: Layout
    let userDefinedMaxPage: Int?
    let isEditMode: Bool
    let pdfScale: CGFloat
    
    // Drag & Drop state management
    @State private var draggedArticle: String? = nil
    @State private var draggedPageNumber: Int? = nil
    @State private var dropLocation: CGPoint = .zero
    @State private var draggedPages: [Layout.Page]? = nil
    @State private var dropTargetPageNumber: Int? = nil
    @State private var mouseLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var dropIndicatorLocation: CGFloat? = nil
    
    // Add .continuous for more responsive tracking
    @GestureState private var dragLocation: CGPoint = .zero
    
    @State private var exportInProgress = false
    
    // MARK: - Methods
    
    private func clearSelection() {
        draggedArticle = nil
        draggedPageNumber = nil
        draggedPages = nil
        isDragging = false
        dropTargetPageNumber = nil
        dropIndicatorLocation = nil
    }
    
    private func handleDrop(at pageNumber: Int) {
        guard let articleName = draggedArticle else { return }
        
        var updatedLayout = layout
        if updatedLayout.moveArticle(articleName, toStartPage: pageNumber) {
            // TODO: Notify PublicationManager about the change
            Task {
                await manager.refreshLayouts()
            }
        }
        
        clearSelection()
    }
    
    private func updateMouseLocation(_ location: CGPoint) {
        mouseLocation = location
        // Módosítjuk az előnézet pozícióját, hogy jobb alul kezdődjön
        dropLocation = CGPoint(x: location.x + 20, y: location.y + 20)
    }
    
    private func updateDropIndicator(at location: CGPoint, in geometry: GeometryProxy) {
        // Calculate position relative to the scrollview content
        let relativePosition = CGPoint(
            x: location.x - geometry.frame(in: .global).minX,
            y: location.y - geometry.frame(in: .global).minY
        )
        
        // Find nearest valid drop position
        let rowIndex = Int(relativePosition.y / (defaultPageSize.height * pdfScale + 20))
        let columnIndex = Int(relativePosition.x / (defaultPageSize.width * pdfScale * 2 + 20))
        
        if columnIndex >= 0 && columnIndex < 5 {
            dropIndicatorLocation = CGFloat(columnIndex) * (defaultPageSize.width * pdfScale * 2 + 20)
        }
    }
    
    private func onDragStarted(page: Layout.Page) {
        if isEditMode {
            draggedArticle = page.articleName
            draggedPageNumber = page.pageNumber
            draggedPages = layout.pages.filter { $0.articleName == page.articleName }
            isDragging = true
            // Initialize the drop location to the mouse position
            updateMouseLocation(mouseLocation)
        }
    }
    
    // MARK: - Computed Properties
    
    /// A tényleges maximum oldalszám (felhasználói vagy számított
    private var effectiveMaxPageNumber: Int {
        userDefinedMaxPage ?? max(
            self.layout.pages.map(\.pageNumber).max() ?? 0,
            self.layout.pageCount
        )
    }
    
    /// Kiszámítja az alapértelmezett oldalméretet a layout alapján
    private var defaultPageSize: CGSize {
        if let firstPage = layout.pages.first?.pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .trimBox)
            return CGSize(width: bounds.width, height: bounds.height)
        }
        return CGSize(width: 595, height: 842)  // A4 alapértelmezett méret
    }
    
    /// Oldalpárok létrehozása
    private var pagePairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] {
        var pairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] = []
        let sortedPages = layout.pages.sorted { $0.pageNumber < $1.pageNumber }
        
        if effectiveMaxPageNumber < 1 { return pairs }
        
        // Az első oldal mindig jobbra kerül (1-es oldalszám)
        pairs.append((
            leftNumber: 0,
            rightNumber: 1,
            left: nil,
            right: sortedPages.first { $0.pageNumber == 1 }
        ))
        
        // A többi oldalt párba rendezzük
        var currentPageNumber = 2
        while currentPageNumber <= effectiveMaxPageNumber {
            pairs.append((
                leftNumber: currentPageNumber,
                rightNumber: currentPageNumber + 1,
                left: sortedPages.first { $0.pageNumber == currentPageNumber },
                right: sortedPages.first { $0.pageNumber == currentPageNumber + 1 }
            ))
            currentPageNumber += 2
        }
        
        return pairs
    }
    
    private let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 20), count: 5)
    
    private func createPagePairView(for pair: (leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)) -> some View {
        PagePairView(
            leftNumber: pair.leftNumber,
            rightNumber: pair.rightNumber,
            leftPage: pair.left,
            rightPage: pair.right,
            scale: pdfScale,
            defaultSize: defaultPageSize,
            draggedArticle: draggedArticle,
            isEditMode: isEditMode,
            onDragStarted: { page in
                if isEditMode {
                    draggedArticle = page.articleName
                    draggedPageNumber = page.pageNumber
                    draggedPages = layout.pages.filter { $0.articleName == page.articleName }
                    isDragging = true
                    // Initialize the drop location to the mouse position
                    updateMouseLocation(mouseLocation)
                }
            },
            maxPageNumber: effectiveMaxPageNumber,
            handleDrop: handleDrop,
            onHover: { isTargeted, pageNumber in
                if isTargeted {
                    dropTargetPageNumber = pageNumber
                } else {
                    dropTargetPageNumber = nil
                }
            }
        )
    }

    private func createPageView(
        page: Layout.Page?,
        pageNumber: Int,
        isDragging: Bool
    ) -> some View {
        PageView(
            page: page,
            scale: pdfScale,
            defaultSize: defaultPageSize,
            isDragging: isDragging,
            onDragStarted: onDragStarted,
            pageNumber: pageNumber,
            isEditMode: isEditMode,
            maxPageNumber: effectiveMaxPageNumber,
            onDrop: handleDrop,
            onHover: { isTargeted, pageNumber in
                if isTargeted {
                    dropTargetPageNumber = pageNumber
                } else {
                    dropTargetPageNumber = nil
                }
            }
        )
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if isDragging {
                        updateMouseLocation(value.location)
                    }
                }
                .onEnded { _ in
                    if isDragging, let targetPage = dropTargetPageNumber {
                        handleDrop(at: targetPage)
                    }
                }
        )
    }
    
    /// Kirajzolja az oldalszámokat az oldalpár alá
    private func drawPageNumbers(leftNumber: Int, rightNumber: Int, x: CGFloat, y: CGFloat, pairWidth: CGFloat) {
        let font = NSFont.systemFont(ofSize: 20 * pdfScale)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black
        ]
        
        // Bal oldalszám
        if leftNumber > 0 {
            let text = NSString(string: String(leftNumber))
            text.draw(
                at: NSPoint(x: x + 10 * pdfScale, y: y - 40 * pdfScale),
                withAttributes: textAttributes
            )
        }
        
        // Jobb oldalszám
        if rightNumber > 0 {
            let text = NSString(string: String(rightNumber))
            let size = text.size(withAttributes: textAttributes)
            text.draw(
                at: NSPoint(x: x + pairWidth - size.width - 10 * pdfScale, y: y - 40 * pdfScale),
                withAttributes: textAttributes
            )
        }
    }
    
    private func exportCurrentView() async {
        guard let publication = manager.publication else { return }
        
        // Kiszámoljuk a teljes méreteket
        let spacing = 100.0 * pdfScale
        let rowCount = Int(ceil(Double(pagePairs.count) / 5))
        let pairWidth = defaultPageSize.width * pdfScale * 2
        let pairHeight = defaultPageSize.height * pdfScale
        
        // A teljes méret az összes sorral, spacing-gel és padding-gal
        let totalWidth = spacing + (pairWidth + spacing) * 5 + spacing
        let totalHeight = spacing + (pairHeight + spacing + 20 * pdfScale) * CGFloat(rowCount) + spacing // Extra hely az oldalszámoknak
        
        // Létrehozunk egy megfelelő méretű képet
        let image = NSImage(size: NSSize(width: totalWidth, height: totalHeight))
        image.lockFocus()
        
        // Fehér háttér
        NSColor.white.setFill()
        NSRect(x: 0, y: 0, width: totalWidth, height: totalHeight).fill()
        
        // Kirajzoljuk az összes oldalpárt
        for (index, pair) in pagePairs.enumerated() {
            let row = index / 5
            let col = index % 5
            
            let x = spacing + CGFloat(col) * (pairWidth + spacing)
            let y = totalHeight - spacing - (CGFloat(row + 1) * (pairHeight + spacing + 20 * pdfScale))
            
            // Oldalpár fekete kerete
            let pairRect = NSRect(
                x: x,
                y: y,
                width: pairWidth,
                height: pairHeight
            )
            NSColor.black.withAlphaComponent(0.3).setStroke()
            let borderPath = NSBezierPath(rect: pairRect)
            borderPath.lineWidth = 0.5 * pdfScale
            borderPath.stroke()
            
            // Oldalszámok kirajzolása
            drawPageNumbers(
                leftNumber: pair.leftNumber,
                rightNumber: pair.rightNumber,
                x: x,
                y: y,
                pairWidth: pairWidth
            )
            
            // Bal oldal
            let leftRect = NSRect(
                x: x,
                y: y,
                width: defaultPageSize.width * pdfScale,
                height: pairHeight
            )
            
            if let leftPage = pair.left?.pdfDocument.page(at: 0) {
                NSGraphicsContext.current?.cgContext.saveGState()
                NSGraphicsContext.current?.cgContext.translateBy(x: x, y: y)
                NSGraphicsContext.current?.cgContext.scaleBy(x: pdfScale, y: pdfScale)
                leftPage.draw(with: .trimBox, to: NSGraphicsContext.current!.cgContext)
                NSGraphicsContext.current?.cgContext.restoreGState()
                
                // Piros keret ha kell
                drawRedBorder(at: leftRect,
                             isPDFFromWorkflow: pair.left?.pdfSource.isSubfolder(of: publication.pdfFolder) ?? true)
            } else if pair.leftNumber > 0 && pair.leftNumber <= effectiveMaxPageNumber {
                NSColor.gray.withAlphaComponent(0.1).setFill()
                leftRect.fill()
                drawPageNumber(pair.leftNumber, at: leftRect)
            }
            
            // Jobb oldal
            let rightRect = NSRect(
                x: x + defaultPageSize.width * pdfScale,
                y: y,
                width: defaultPageSize.width * pdfScale,
                height: pairHeight
            )
            
            if let rightPage = pair.right?.pdfDocument.page(at: 0) {
                NSGraphicsContext.current?.cgContext.saveGState()
                NSGraphicsContext.current?.cgContext.translateBy(x: x + defaultPageSize.width * pdfScale, y: y)
                NSGraphicsContext.current?.cgContext.scaleBy(x: pdfScale, y: pdfScale)
                rightPage.draw(with: .trimBox, to: NSGraphicsContext.current!.cgContext)
                NSGraphicsContext.current?.cgContext.restoreGState()
                
                // Piros keret ha kell
                drawRedBorder(at: rightRect,
                             isPDFFromWorkflow: pair.right?.pdfSource.isSubfolder(of: publication.pdfFolder) ?? true)
            } else if pair.rightNumber > 0 && pair.rightNumber <= effectiveMaxPageNumber {
                NSColor.gray.withAlphaComponent(0.1).setFill()
                rightRect.fill()
                drawPageNumber(pair.rightNumber, at: rightRect)
            }
        }
        
        image.unlockFocus()
        
        // JPG fájl mentése
        // TODO: fájlelnevezés rendbetétele
        let fileName = "\(manager.publication!.name) –  layout"
        let fileURL = publication.baseFolder.appendingPathComponent(fileName).appendingPathExtension("jpg")
        
        if let imageData = image.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: imageData),
           let jpgData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.5]) {
            try? jpgData.write(to: fileURL)
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
    }
    
    /// Rajzol egy nagyméretű oldalszámot a megadott helyre
    private func drawPageNumber(_ number: Int, at rect: NSRect) {
        let text = NSString(string: String(number))
        let font = NSFont.systemFont(ofSize: 60 * pdfScale)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.gray.withAlphaComponent(0.3)
        ]
        
        let size = text.size(withAttributes: attributes)
        let x = rect.minX + (rect.width - size.width) / 2
        let y = rect.minY + (rect.height - size.height) / 2
        
        text.draw(at: NSPoint(x: x, y: y), withAttributes: attributes)
    }
    
    /// Rajzol egy piros keretet a megadott területre
    private func drawRedBorder(at rect: NSRect, isPDFFromWorkflow: Bool = false) {
        if !isPDFFromWorkflow {
            NSColor.red.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2.0 * pdfScale
            path.stroke()
        }
    }
    
    var body: some View {
        let spacing = 20 * pdfScale
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                ZStack(alignment: .topLeading) {
                    LazyVGrid(columns: columns, spacing: spacing) {
                        ForEach(pagePairs.indices, id: \.self) { index in
                            createPagePairView(for: pagePairs[index])
                        }
                    }
                    .padding()
                    
                    // Preview with white background
                    if isDragging,
                       let pages = draggedPages {
                        HStack(spacing: 4) {
                            ForEach(pages, id: \.pageNumber) { page in
                                PDFPageRendererView(
                                    pdfPage: page.pdfDocument.page(at: 0)!,
                                    displayBox: .trimBox,
                                    scale: pdfScale * 0.5
                                )
                                .frame(
                                    width: defaultPageSize.width * pdfScale * 0.5,
                                    height: defaultPageSize.height * pdfScale * 0.5
                                )
                            }
                        }
                        .background(Color.white.opacity(0.7))
                        .position(dropLocation)
                    }
                    
                    // Drop indicator with higher opacity
                    if let dropLocation = dropIndicatorLocation,
                       isDragging {
                        Rectangle()
                            .fill(Color.blue.opacity(0.8))
                            .frame(width: 4)  // Make it slightly thicker
                            .frame(height: geometry.size.height)
                            .position(x: dropLocation, y: geometry.size.height / 2)
                            .animation(.easeInOut(duration: 0.2), value: dropLocation)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .global)
                        .onChanged { value in
                            if isDragging {
                                updateMouseLocation(value.location)
                                updateDropIndicator(at: value.location, in: geometry)
                            }
                        }
                        .onEnded { _ in
                            if isDragging, let targetPage = dropTargetPageNumber {
                                handleDrop(at: targetPage)
                            }
                            dropIndicatorLocation = nil
                        }
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    clearSelection()
                }
                .onChange(of: isEditMode) { _, newValue in
                    if !newValue {
                        clearSelection()
                    }
                }
            }
        }
        // Add keyboard handling for Esc key
        .onKeyPress(.escape) {
            clearSelection()
            return .handled
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Previous toolbar items remain the same
                
                // Add separator
                Divider()
                
                // Export button
                Button {
                    exportInProgress = true
                    Task {
                        await exportCurrentView()
                        exportInProgress = false
                    }
                } label: {
                    if exportInProgress {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Image(systemName: "photo")
                    }
                }
                .help("Exportálás JPG formátumba")
                .disabled(exportInProgress)
            }
        }
    }
}
