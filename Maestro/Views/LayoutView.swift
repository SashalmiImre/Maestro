import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct LayoutView: View {
    @EnvironmentObject var manager: PublicationManager
    @EnvironmentObject var context: LayoutViewContext
    
    let layout: Layout
    
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
            .onChange(of: manager.isEditMode) { newValue in
                if !newValue {
                    // clearSelection()
                }
            }
            .onChange(of: manager.isExporting) { newValue in
                // Simplified layout check using the already implemented Equatable
                if layout == manager.selectedLayout && newValue == true {
                    saveToPDF()
                }
            }
            .onAppear {
                keyDownHandler()
            }
    }
    
    private var pagesGrid: some View {
        let pagePairs = layout.pagePairs(maxPageCount: manager.maxPageNumber)
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
    
    @discardableResult
    private func keyDownHandler() -> Any? {
        return NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "0":
                    withAnimation {
                        // Zoom to fit current page
                        if let pageSize = manager.layouts.first?.maxPageSize(for: .trimBox) {
                            let availableSize = context.scrollViewAvaiableSize
                            let availableWidth = availableSize.width - spacing * 2
                            let availableHeight = availableSize.height - spacing * 2
                            let zoomX = availableWidth / (pageSize.width * 2)
                            let zoomY = availableHeight / pageSize.height
                            manager.zoomLevel = max(0.1, min(zoomX, zoomY))
                        }
                    }
                    return nil
                    
                case "1":
                    withAnimation {
                        // Adjust zoom to fit layout width
                        if let pageWidth = manager.selectedLayout?.maxPageSize(for: .trimBox).width {
                            let totalWidth = (pageWidth * 2.0 * CGFloat(manager.layoutColumns)) + (spacing * CGFloat(manager.layoutColumns - 1))
                            let availableSize = context.scrollViewAvaiableSize
                            let availableWidth = availableSize.width - spacing * 2
                            manager.zoomLevel = max(0.1, availableWidth / totalWidth)
                        }
                    }
                    return nil
                    
                case "3":
                    withAnimation {
                        // Zoom to fit current page pair
                        if let pagePair = layout.pagePairs(maxPageCount: manager.maxPageNumber)
                            .first(where: { $0.coverage.contains(manager.currentPageNumber) }),
                           let pageSize = manager.layouts.first?.maxPageSize(for: .trimBox) {
                            let pairWidth = pageSize.width * 2
                            let availableSize = context.scrollViewAvaiableSize
                            let availableWidth = availableSize.width - spacing * 2
                            let availableHeight = availableSize.height - spacing * 2
                            let zoomX = availableWidth / pairWidth
                            let zoomY = availableHeight / pageSize.height
                            manager.zoomLevel = max(0.1, min(zoomX, zoomY))
                        }
                    }
                    return nil
                    
                default:
                    break
                }
            }
            return event
        }
    }
    

    
    private func saveToPDF() {
        Task {
            // Calculate the total size needed
            let pageSize = manager.layouts.first!.maxPageSize(for: .trimBox)
            let pairCount = layout.pagePairs(maxPageCount: manager.maxPageNumber).count
            let rowCount = Int(ceil(Double(pairCount) / Double(manager.layoutColumns))) + 1
            let columnCount = min(pairCount, manager.layoutColumns)
            
            // Calculate total width and height including spacing
            let totalWidth = (pageSize.width * 2 * CGFloat(columnCount) * manager.zoomLevel) + (spacing * CGFloat(columnCount - 1)) + (spacing * 2)
            let totalHeight = (pageSize.height * CGFloat(rowCount) * manager.zoomLevel) + (spacing * CGFloat(rowCount - 1)) + (spacing * 2)
            
            let mediaBox = CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight)
            
            let renderer = ImageRenderer(content: self.environmentObject(manager))
            renderer.proposedSize = ProposedViewSize(width: totalWidth, height: totalHeight)
            
            // Configure the renderer
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
                        manager.isExporting = false
                    }
                }
            }
        }
    }
    
    // Add PreferenceKey for content size
    private struct ContentSizePreferenceKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
    
    // Add new PreferenceKey for view size
    private struct ViewSizeKey: PreferenceKey {
        static var defaultValue: CGSize = .zero
        
        static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
            value = nextValue()
        }
    }
}
