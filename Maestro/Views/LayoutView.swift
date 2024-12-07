import SwiftUI
import PDFKit

struct LayoutView: View {
    let layout: Layout
    private let pdfScale: CGFloat = 0.2  // A PDF méretének 1/10-e
    
    /// Kiszámítja az alapértelmezett oldalméretet a layout alapján
    private var defaultPageSize: CGSize {
        // Megpróbáljuk megállapítani az első nem üres oldalból
        if let firstPage = layout.layoutPages.first?.pdfDocument.page(at: 0) {
            let bounds = firstPage.bounds(for: .mediaBox)
            return CGSize(width: bounds.width, height: bounds.height)
        }
        // Ha nincs oldal, A4-es méretarányt használunk (595 x 842 pont)
        return CGSize(width: 595, height: 842)
    }
    
    /// Egy oldalpár megjelenítése
    private struct PagePairView: View {
        let leftNumber: Int
        let rightNumber: Int
        let leftPage: Layout.Page?
        let rightPage: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        
        var body: some View {
            VStack(spacing: 2) {  // A számok és az oldalak között kis térköz
                HStack(spacing: 0) {  // Szorosan egymás mellett
                    // Bal oldal
                    PageView(page: leftPage, scale: scale, defaultSize: defaultSize)
                    
                    // Jobb oldal
                    PageView(page: rightPage, scale: scale, defaultSize: defaultSize)
                }
                .background(Color.white)
                .cornerRadius(4)
                .shadow(radius: 2)
                
                // Oldalszámok külön sorban
                HStack(spacing: 0) {
                    if let leftNumber = leftPage?.pageNumber {
                        Text("\(leftNumber)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .frame(width: defaultSize.width * scale, alignment: .leading)
                    } else {
                        Color.clear
                            .frame(width: defaultSize.width * scale)
                    }
                    
                    if let rightNumber = rightPage?.pageNumber {
                        Text("\(rightNumber)")
                            .font(.system(size: 8))
                            .foregroundColor(.gray)
                            .frame(width: defaultSize.width * scale, alignment: .trailing)
                    } else {
                        Color.clear
                            .frame(width: defaultSize.width * scale)
                    }
                }
            }
        }
    }
    
    /// Egy oldal megjelenítése
    private struct PageView: View {
        let page: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        
        var body: some View {
            Group {
                if let page = page {
                    PDFKitView(document: page.pdfDocument, scale: scale)
                        .frame(
                            width: defaultSize.width * scale,
                            height: defaultSize.height * scale
                        )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(
                            width: defaultSize.width * scale,
                            height: defaultSize.height * scale
                        )
                }
            }
        }
    }
    
    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVStack(spacing: 20) {
                ForEach(0..<Int(ceil(Double(layout.pageCount) / 10)), id: \.self) { rowIndex in
                    HStack(spacing: 20) {
                        ForEach(0..<5, id: \.self) { pairIndex in
                            if pairIndex == 0 && rowIndex == 0 {
                                // Első oldalpár: üres bal oldal, 1. oldal jobbra
                                PagePairView(
                                    leftNumber: 0,     // Üres oldal száma
                                    rightNumber: 1,    // Első oldal száma
                                    leftPage: nil,     // Mindig üres
                                    rightPage: layout.layoutPages.first(where: { $0.pageNumber == 1 }),
                                    scale: pdfScale,
                                    defaultSize: defaultPageSize
                                )
                            } else {
                                let leftNumber = (rowIndex * 10 + pairIndex * 2)
                                let rightNumber = leftNumber + 1
                                
                                PagePairView(
                                    leftNumber: leftNumber,
                                    rightNumber: rightNumber,
                                    leftPage: layout.layoutPages.first(where: { $0.pageNumber == leftNumber }),
                                    rightPage: layout.layoutPages.first(where: { $0.pageNumber == rightNumber }),
                                    scale: pdfScale,
                                    defaultSize: defaultPageSize
                                )
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
    }
}

/// PDFKit wrapper SwiftUI-hoz
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    let scale: CGFloat
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = false
        view.scaleFactor = scale
        view.backgroundColor = .clear
        
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
        nsView.scaleFactor = scale
    }
} 
