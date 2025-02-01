import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct LayoutView: View {
    @EnvironmentObject var manager: PublicationManager
    @EnvironmentObject var context: LayoutViewContext
    
    let layout: Layout
    
    @State private var eventMonitor: Any?
    @State private var pagePairs: [PagePair] = []
    @State private var maxPageSize: CGSize = .zero
    
    // MARK: - Layout Properties
    
    private var spacing: CGFloat {
        80 * manager.zoomLevel
    }
    
    var body: some View {
        pagesGrid
            .animation(.easeInOut(duration: 0.3), value: manager.layoutColumns)
            .onTapGesture {
                // clearSelection()
            }
            .onChange(of: manager.isEditMode) { _, newValue in
                if !newValue {
                    // clearSelection()
                }
            }
            .onChange(of: manager.isExporting) { _, newValue in
                if layout == manager.selectedLayout && newValue == true {
                    saveToPDF()
                }
            }
            .onAppear {
                eventMonitor = keyDownHandler()
                loadPagePairs()
                loadMaxPageSize()
            }
            .onDisappear {
                if let monitor = eventMonitor {
                    NSEvent.removeMonitor(monitor)
                    eventMonitor = nil
                    print("Event monitor removed.")
                } else {
                    print("No event monitor to remove.")
                }
            }
    }
    
    private var pagesGrid: some View {
        let pagePairsCount = pagePairs.count
        let rowNumber = Int(ceil(Double(pagePairsCount) / Double(manager.layoutColumns)))
        
        return Grid(horizontalSpacing: spacing, verticalSpacing: spacing) {
            ForEach(0..<rowNumber, id: \.self) { row in
                GridRow {
                    ForEach(0..<manager.layoutColumns, id: \.self) { column in
                        let index = row * manager.layoutColumns + column
                        if index < pagePairsCount {
                            let pagePair = pagePairs[index]
                            PagePairView(pagePair: pagePair)
                                .id(pagePair.coverage.lowerBound)
                                .environmentObject(manager)
                        } else {
                            Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
                        }
                    }
                }
            }
        }
        .padding(spacing)
        .background(Color.clear)
    }
    
    private func keyDownHandler() -> Any? {
        return NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "0":
                    Task {
                        await zoomToFitCurrentPage()
                    }
                case "1":
                    Task {
                        await zoomToFitLayoutWidth()
                    }
                case "3":
                    Task {
                        await zoomToFitCurrentPagePair()
                    }
                default:
                    break
                }
            }
            return event
        }
    }
    
    private func loadPagePairs() {
        Task {
            self.pagePairs = await layout.pagePairs(maxPageCount: manager.maxPageNumber)
        }
    }
    
    private func loadMaxPageSize() {
        Task {
            if let rect = await manager.layouts.first?.maxPageSize(for: .trimBox) {
                self.maxPageSize = rect.size
            }
        }
    }
    
    private func zoomToFitCurrentPage() async {
        let availableSize = context.scrollViewAvaiableSize
        let availableWidth = availableSize.width - spacing * 2
        let availableHeight = availableSize.height - spacing * 2
        let zoomX = availableWidth / (maxPageSize.width * 2)
        let zoomY = availableHeight / maxPageSize.height
        await MainActor.run {
            withAnimation {
                manager.zoomLevel = max(0.1, min(zoomX, zoomY))
            }
        }
    }
    
    private func zoomToFitLayoutWidth() async {
        let totalWidth = (maxPageSize.width * 2.0 * CGFloat(manager.layoutColumns)) + (spacing * CGFloat(manager.layoutColumns - 1))
        let availableSize = context.scrollViewAvaiableSize
        let availableWidth = availableSize.width - spacing * 2
        await MainActor.run {
            withAnimation {
                manager.zoomLevel = max(0.1, availableWidth / totalWidth)
            }
        }
    }
    
    private func zoomToFitCurrentPagePair() async {
        if let pagePair = pagePairs.first(where: { $0.coverage.contains(manager.currentPageNumber) }) {
            let pairWidth = maxPageSize.width * 2
            let availableSize = context.scrollViewAvaiableSize
            let availableWidth = availableSize.width - spacing * 2
            let availableHeight = availableSize.height - spacing * 2
            let zoomX = availableWidth / pairWidth
            let zoomY = availableHeight / maxPageSize.height
            await MainActor.run {
                withAnimation {
                    manager.zoomLevel = max(0.1, min(zoomX, zoomY))
                }
            }
        }
    }
    
    private func saveToPDF() {
        Task {
            let pairCount = pagePairs.count
            let rowCount = Int(ceil(Double(pairCount) / Double(manager.layoutColumns))) + 1
            let columnCount = min(pairCount, manager.layoutColumns)
            
            let totalWidth = (maxPageSize.width * 2 * CGFloat(columnCount) * manager.zoomLevel) + (spacing * CGFloat(columnCount - 1)) + (spacing * 2)
            let totalHeight = (maxPageSize.height * CGFloat(rowCount) * manager.zoomLevel) + (spacing * CGFloat(rowCount - 1)) + (spacing * 2)
            
            let mediaBox = CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
            
            let renderer = ImageRenderer(content: self.environmentObject(manager))
            renderer.proposedSize = ProposedViewSize(width: totalWidth, height: totalHeight)
            
            renderer.scale = 1.0
            renderer.isOpaque = false
            
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [UTType.pdf]
            savePanel.nameFieldStringValue = "output.pdf"
            savePanel.begin { response in
                if response == .OK, let url = savePanel.url {
                    withUnsafePointer(to: mediaBox) { mediaBoxPointer in
                        if let context = CGContext(url as CFURL, mediaBox: mediaBoxPointer, nil) {
                            renderer.render { size, draw in
                                context.beginPDFPage(nil)
                                draw(context)
                                context.endPDFPage()
                                context.closePDF()
                            }
                            
                            print("PDF saved at \(url)")
                        } else {
                            print("Failed to create PDF context")
                        }
                        Task { @MainActor in
                            manager.isExporting = false
                        }
                    }
                }
            }
        }
    }
}
