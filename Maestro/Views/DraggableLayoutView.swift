import SwiftUI
import PDFKit

struct DraggableLayoutView: View {
    let layout: Layout
    private let pdfScale: CGFloat = 0.2
    
    // Drag & Drop állapot kezelése
    @State private var draggedArticle: String? = nil
    @State private var draggedPageNumber: Int? = nil
    @State private var dropLocation: CGPoint = .zero
    
    // MARK: - Computed Properties
    
    /// Kiszámítja az alapértelmezett oldalméretet a layout alapján
    private var defaultPageSize: CGSize {
        if let firstPage = layout.layoutPages.first?.pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            return CGSize(width: bounds.width, height: bounds.height)
        }
        return CGSize(width: 595, height: 842)
    }
    
    /// Oldalpárok létrehozása
    private var pagePairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] {
        var pairs: [(leftNumber: Int, rightNumber: Int, left: Layout.Page?, right: Layout.Page?)] = []
        let sortedPages = layout.layoutPages.sorted { $0.pageNumber < $1.pageNumber }
        
        // Meghatározzuk a legnagyobb oldalszámot
        let maxPageNumber = sortedPages.map(\.pageNumber).max() ?? 0
        if maxPageNumber < 1 { return pairs }
        
        // Az első oldal mindig jobbra kerül (1-es oldalszám)
        pairs.append((
            leftNumber: 0,
            rightNumber: 1,
            left: nil,
            right: sortedPages.first { $0.pageNumber == 1 }
        ))
        
        // A többi oldalt párba rendezzük
        var currentPageNumber = 2
        while currentPageNumber <= maxPageNumber {
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
    
    // MARK: - Subviews
    
    /// Egy oldal megjelenítése drag & drop támogatással
    private struct DraggablePageView: View {
        let page: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        let isDragging: Bool
        let onDragStarted: (Layout.Page) -> Void
        let pageNumber: Int
        
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
                            onDragStarted(page)
                        }
                } else if pageNumber > 0 {  // Csak akkor jelenítjük meg az üres oldalt, ha van érvényes oldalszám
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(
                            width: defaultSize.width * scale,
                            height: defaultSize.height * scale
                        )
                        .overlay(
                            Text("\(pageNumber)")  // A helyes oldalszám megjelenítése
                                .font(.system(size: 60))
                                .foregroundColor(.gray.opacity(0.3))
                        )
                        .cornerRadius(4)
                        .shadow(radius: 2)
                }
            }
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
        let onDragStarted: (Layout.Page) -> Void
        
        var body: some View {
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    // Bal oldal
                    DraggablePageView(
                        page: leftPage,
                        scale: scale,
                        defaultSize: defaultSize,
                        isDragging: leftPage.map { draggedArticle == $0.articleName } ?? false,
                        onDragStarted: onDragStarted,
                        pageNumber: leftNumber
                    )
                    
                    // Jobb oldal
                    DraggablePageView(
                        page: rightPage,
                        scale: scale,
                        defaultSize: defaultSize,
                        isDragging: rightPage.map { draggedArticle == $0.articleName } ?? false,
                        onDragStarted: onDragStarted,
                        pageNumber: rightNumber
                    )
                }
                .frame(height: defaultSize.height * scale)
                .background(Color.white)
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
                    
                    Text("\(rightNumber)")
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
            LazyVStack(spacing: 20, pinnedViews: []) {
                ForEach(0..<Int(ceil(Double(layout.pageCount) / 10)), id: \.self) { rowIndex in
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { pairIndex in
                            let pairOffset = rowIndex * 5 + pairIndex
                            if pairOffset < pagePairs.count {
                                let pair = pagePairs[pairOffset]
                                PagePairView(
                                    leftNumber: pair.leftNumber,
                                    rightNumber: pair.rightNumber,
                                    leftPage: pair.left,
                                    rightPage: pair.right,
                                    scale: pdfScale,
                                    defaultSize: defaultPageSize,
                                    draggedArticle: draggedArticle,
                                    onDragStarted: { page in
                                        draggedArticle = page.articleName
                                        draggedPageNumber = page.pageNumber
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
            }
            .padding()
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

#Preview {
    DraggableLayoutView(layout: Layout()) // Tesztadatokkal kellene feltölteni
} 
