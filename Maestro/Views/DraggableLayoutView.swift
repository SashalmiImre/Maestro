import SwiftUI
import PDFKit

// PDFKitView definíciója
struct PDFKitView: View {
    let document: PDFDocument
    let scale: CGFloat
    
    var body: some View {
        PDFKitRepresentedView(document: document, scale: scale)
            .allowsHitTesting(false)
    }
}

// PDFKit wrapper
struct PDFKitRepresentedView: NSViewRepresentable {
    let document: PDFDocument
    let scale: CGFloat
    
    func makeNSView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.maxScaleFactor = 4.0
        pdfView.minScaleFactor = 0.1
        pdfView.scaleFactor = scale
        
        // Csak egy oldalt jelenítünk meg, és letiltjuk a görgetést
        pdfView.displayMode = .singlePage
        pdfView.displaysAsBook = false
        pdfView.displayDirection = .vertical
        
        return pdfView
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
        nsView.scaleFactor = scale
    }
}

struct DraggableLayoutView: View {
    let layout: Layout
    let userDefinedMaxPage: Int?
    let isEditMode: Bool
    private let pdfScale: CGFloat = 0.2
    
    // Drag & Drop állapot kezelése
    @State private var draggedArticle: String? = nil
    @State private var draggedPageNumber: Int? = nil
    @State private var dropLocation: CGPoint = .zero
    
    // MARK: - Methods
    
    private func clearSelection() {
        draggedArticle = nil
        draggedPageNumber = nil
    }
    
    // MARK: - Computed Properties
    
    /// A tényleges maximum oldalszám (felhasználói vagy számított)
    private var effectiveMaxPageNumber: Int {
        userDefinedMaxPage ?? max(
            layout.layoutPages.map(\.pageNumber).max() ?? 0,
            layout.pageCount
        )
    }
    
    /// Kiszámítja az alapértelmezett oldalméretet a layout alapján
    private var defaultPageSize: CGSize {
        if let firstPage = layout.layoutPages.first?.pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            return CGSize(width: bounds.width, height: bounds.height)
        }
        return CGSize(width: 595, height: 842)  // A4 alapértelmezett méret
    }
    
    /// Oldalpárok létrehozása
    private var pagePairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] {
        var pairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] = []
        let sortedPages = layout.layoutPages.sorted { $0.pageNumber < $1.pageNumber }
        
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
    
    private var rowCount: Int {
        Int(ceil(Double(pagePairs.count) / 5))
    }
    
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
                }
            },
            maxPageNumber: effectiveMaxPageNumber
        )
    }
    
    // MARK: - Subviews
    
    /// Üres oldal
    private struct BlankPageView: View {
        let scale: CGFloat
        let defaultSize: CGSize
        var body: some View {
            Color.clear
                .frame(width: defaultSize.width * scale, height: defaultSize.height * scale)
        }
    }
    
    /// Egy oldal megjelenítése drag & drop támogatással
    private struct DraggablePageView: View {
        let page: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        let isDragging: Bool
        let onDragStarted: (Layout.Page) -> Void
        let pageNumber: Int
        let isEditMode: Bool
        let maxPageNumber: Int
        
        var body: some View {
            Group {
                if let page = page {
                    PDFKitView(document: page.pdfDocument, scale: scale)
                        .frame(
                            width: defaultSize.width * scale,
                            height: defaultSize.height * scale
                        )
                        .background(Color.white)
                        .cornerRadius(4)
                        .shadow(radius: isDragging ? 8 : 2)
                        .opacity(isDragging ? 0.7 : 1.0)
                        .onTapGesture {
                            if isEditMode {
                                if isDragging {
                                    // Ha a már kijelölt oldalra kattintunk, töröljük a kijelölést
                                    onDragStarted(page)
                                } else {
                                    // Különben kijelöljük az oldalt
                                    onDragStarted(page)
                                }
                            }
                        }
                        .overlay(
                            isDragging && isEditMode ? Color.blue.opacity(0.3) : Color.clear
                        )
                } else if pageNumber > 0 && pageNumber <= maxPageNumber {  // csak akkor jelenítjük meg az üres oldalt, ha nem nagyobb a maxPageNumber-nél
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(
                            width: defaultSize.width * scale,
                            height: defaultSize.height * scale
                        )
                        .overlay(
                            Text("\(pageNumber)")
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                        .cornerRadius(4)
                        .shadow(radius: 2)
                }
            }
            .background(Color.white)
            .frame(width: defaultSize.width * scale, height: defaultSize.height * scale)
        }
    }
    
    /// Egy oldalpár megjelenítése
    private struct PagePairView: View {
        let leftNumber: Int
        let rightNumber: Int
        let leftPage: Layout.Page?
        let rightPage: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        let draggedArticle: String?
        let isEditMode: Bool
        let onDragStarted: (Layout.Page) -> Void
        let maxPageNumber: Int
        
        var body: some View {
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    // Bal oldal
                    if leftNumber > 0 {
                        DraggablePageView(
                            page: leftPage,
                            scale: scale,
                            defaultSize: defaultSize,
                            isDragging: leftPage.map { draggedArticle == $0.articleName } ?? false,
                            onDragStarted: onDragStarted,
                            pageNumber: leftNumber,
                            isEditMode: isEditMode,
                            maxPageNumber: maxPageNumber
                        )
                        .scrollDisabled(true)
                    } else {
                        BlankPageView(scale: scale, defaultSize: defaultSize)
                    }
                    
                    // Jobb oldal
                    if rightNumber <= maxPageNumber {
                        DraggablePageView(
                            page: rightPage,
                            scale: scale,
                            defaultSize: defaultSize,
                            isDragging: rightPage.map { draggedArticle == $0.articleName } ?? false,
                            onDragStarted: onDragStarted,
                            pageNumber: rightNumber,
                            isEditMode: isEditMode,
                            maxPageNumber: maxPageNumber
                        )
                        .scrollDisabled(true)
                    } else {
                        BlankPageView(scale: scale, defaultSize: defaultSize)
                    }
                }
                .frame(width: defaultSize.width * scale * 2, height: defaultSize.height * scale)
                .cornerRadius(4)
                .shadow(radius: 2)
                
                // Oldalszámok külön sorban
                HStack(spacing: 0) {
                    Text("\(leftNumber)")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .frame(width: defaultSize.width * scale, alignment: .leading)
                        .padding(.leading, 4)
                        .opacity(leftNumber > 0 ? 1 : 0)
                    
                    Text("\(rightNumber <= maxPageNumber ? String(rightNumber) : "")")
                        .font(.system(size: 8))
                        .foregroundColor(.gray)
                        .frame(width: defaultSize.width * scale, alignment: .trailing)
                        .padding(.trailing, 4)
                        .opacity(rightNumber > 0 ? 1 : 0)
                    
                }
            }
        }
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 20) {
                ForEach(0..<rowCount, id: \.self) { rowIndex in
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { pairIndex in
                            let pairOffset = rowIndex * 5 + pairIndex
                            if pairOffset < pagePairs.count {
                                createPagePairView(for: pagePairs[pairOffset])
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .contentShape(Rectangle())  // Az egész területet kattinthatóvá tesszük
        .onTapGesture {
            // Ha üres területre kattintunk, töröljük a kijelölést
            clearSelection()
        }
        .onChange(of: isEditMode) { oldValue, newValue in
            // Ha kikapcsolják a szerkesztést, töröljük a kijelölést
            if !newValue {
                clearSelection()
            }
        }
    }
}

// MARK: - Drop Delegate

private struct LayoutDropDelegate: DropDelegate {
    let layout: Layout
    @Binding var draggedArticle: String?
    @Binding var draggedPageNumber: Int?
    @Binding var dropLocation: CGPoint
    let targetPage: Layout.Page?
    
    func performDrop(info: DropInfo) -> Bool {
        // Itt kell majd implementálni az Article áthelyezését
        draggedArticle = nil
        draggedPageNumber = nil
        return true
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropLocation = info.location
        return DropProposal(operation: .move)
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        guard let draggedArticle = draggedArticle,
              let targetPage = targetPage else { return false }
        return draggedArticle != targetPage.articleName
    }
}

//#Preview {
//    DraggableLayoutView(layout: Layout()) // Tesztadatokkal kellene feltölteni
//}
