import SwiftUI
import PDFKit

struct LayoutView: View {
    let layout: Layout
    
    /// Egy oldalpár megjelenítése
    private struct PagePairView: View {
        let leftPage: Layout.Page?
        let rightPage: Layout.Page?
        
        var body: some View {
            HStack(spacing: 0) {
                // Bal oldal
                PageView(page: leftPage)
                    .scrollDisabled(true)
                
                // Jobb oldal
                PageView(page: rightPage)
                    .scrollDisabled(true)
            }
            .frame(height: 276)  // Fix magasság az oldalpároknak
            .background(Color.white)
            .cornerRadius(4)
            .shadow(radius: 2)
        }
    }
    
    /// Egy oldal megjelenítése
    private struct PageView: View {
        let page: Layout.Page?
        
        var body: some View {
            ZStack {
                if let page = page {
                    PDFKitView(document: page.pdfDocument)
                        .frame(width: 140)  // 2:3 arány a magassághoz
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 140)
                        .overlay(
                            Text("\(page?.pageNumber ?? 0)")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        )
                }
            }
        }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Oldalak csoportosítása soronként (5 pár oldalanként)
                ForEach(0..<Int(ceil(Double(layout.pageCount) / 10)), id: \.self) { rowIndex in
                    HStack(spacing: 10) {
                        // Egy sorban 5 oldalpár
                        ForEach(0..<5, id: \.self) { pairIndex in
                            let startIndex = rowIndex * 10 + pairIndex * 2
                            let pages = layout.layoutPages
                            
                            PagePairView(
                                leftPage: startIndex < pages.count ? pages[startIndex] : nil,
                                rightPage: startIndex + 1 < pages.count ? pages[startIndex + 1] : nil
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

/// PDFKit wrapper SwiftUI-hoz
struct PDFKitView: NSViewRepresentable {
    let document: PDFDocument
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
    }
} 
