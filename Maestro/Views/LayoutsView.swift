import SwiftUI
import PDFKit

struct LayoutsView: View {
    @StateObject private var viewModel: LayoutsViewModel
    
    init(publication: Publication) {
        _viewModel = StateObject(wrappedValue: LayoutsViewModel(publication: publication))
    }
    
    var body: some View {
        VStack {
            // Navigációs gombok és layout információ
            HStack {
                Button(action: viewModel.previousLayout) {
                    Image(systemName: "chevron.left")
                }
                .disabled(!viewModel.hasPreviousLayout)
                
                Text("Layout \(viewModel.selectedLayoutIndex + 1)/\(viewModel.layoutCount)")
                    .font(.headline)
                
                Button(action: viewModel.nextLayout) {
                    Image(systemName: "chevron.right")
                }
                .disabled(!viewModel.hasNextLayout)
            }
            .padding()
            
            // Layout megjelenítése
            if let selectedLayout = viewModel.selectedLayout {
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(1...viewModel.selectedLayoutPageCount, id: \.self) { pageNumber in
                            VStack(alignment: .leading) {
                                // Oldalszám és cikk neve
                                if let articleName = viewModel.articleName(forPage: pageNumber) {
                                    Text("\(pageNumber). oldal - \(articleName)")
                                        .font(.headline)
                                        .padding(.bottom, 5)
                                }
                                
                                // PDF oldal megjelenítése
                                if let pdfDocument = viewModel.pdfDocument(forPage: pageNumber) {
                                    PDFKitView(document: pdfDocument, scale: 0.2)
                                        .frame(height: 800)
                                        .border(Color.gray, width: 1)
                                } else {
                                    Text("PDF nem található")
                                        .foregroundColor(.red)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            } else {
                Text("Nincs elérhető layout")
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Layoutok")
        .toolbar {
            Button(action: viewModel.refreshLayouts) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}
//
//// PDFKitView marad változatlan, ha már létezik
//struct PDFKitView: NSViewRepresentable {
//    let document: PDFDocument
//    
//    func makeNSView(context: Context) -> PDFView {
//        let pdfView = PDFView()
//        pdfView.document = document
//        pdfView.autoScales = true
//        return pdfView
//    }
//    
//    func updateNSView(_ pdfView: PDFView, context: Context) {
//        pdfView.document = document
//    }
//}

//#Preview {
//    LayoutsView(publication: .previewValue)
//} 
