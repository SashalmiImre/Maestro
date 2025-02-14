import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct LayoutView: View {
    @EnvironmentObject var manager: PublicationManager
    @EnvironmentObject var context: LayoutViewContext
    
    let layout: Layout
    
    @State private var pagePairs: [PagePair] = []
    @State private var maxPageSize: CGSize = .zero
    
    // MARK: - Layout Properties
    
    private func getLocalizedDateString(localeIdentifier: String = "hu_HU") -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localeIdentifier)
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: Date())
    }
    
    private var spacing: CGFloat {
        80 * manager.zoomLevel
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 20 * manager.zoomLevel) {
                HStack(alignment: .firstTextBaseline, spacing: 40 * manager.zoomLevel) {
                    Text(manager.publication?.name ?? "Név nélkül")
                        .font(.system(size: 240 * manager.zoomLevel))
                        .fontWeight(.bold)
                    
                    Divider()
                        .frame(minWidth: 40 * manager.zoomLevel)
                    
                    let layoutVersionCharacter = Character(UnicodeScalar(manager.selectedLayoutIndex + 65)!)
                    Text("\(layoutVersionCharacter) - elrendezés")
                        .font(.system(size: 160 * manager.zoomLevel))
                }
                
                Divider()
                    .padding(.top, 40 * manager.zoomLevel)
                
                Text("Készítette: \(NSFullUserName())")
                    .font(.system(size: 60 * manager.zoomLevel))
                
                Text("Dátum: \(getLocalizedDateString())")
                    .font(.system(size: 60 * manager.zoomLevel))
                
                Divider()
            }
            .padding(spacing)
            
            pagesGrid
        }
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        context.scrollViewContentSize = geometry.size
                    }
                    .onChange(of: geometry.size) { _, newSize in
                        context.scrollViewContentSize = newSize
                        print("LayoutView size: \(newSize)")
                    }
            }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .task {
            loadPagePairs()
            loadMaxPageSize()
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
                                .id("PagePair\(pagePair.coverage.lowerBound)")
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
        .fixedSize(horizontal: true, vertical: true)
    }
    
    private func loadPagePairs() {
        Task {
            self.pagePairs = await layout.pagePairs(maxPageCount: manager.maxPageNumber)
        }
    }
    
    private func loadMaxPageSize() {
        Task {
            if let rect = manager.layouts.first?.maxPageSizes[.trimBox] {
                self.maxPageSize = rect.size
            }
        }
    }
    
    private func saveToPDF() {
        Task {
            let mediaBox    = CGRect(origin: .zero, size: context.scrollViewContentSize)
            let renderer    = ImageRenderer(content: self
                .environmentObject(manager)
                .environmentObject(context))
            renderer.proposedSize = ProposedViewSize(width: mediaBox.width, height: mediaBox.height)
            
            renderer.scale    = 1.0
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
