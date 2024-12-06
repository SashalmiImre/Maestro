import SwiftUI
import PDFKit

struct PDFKitView: NSViewRepresentable {
    let document: PDFKit.PDFDocument
    let pageNumber: Int
    
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        if let page = document.page(at: pageNumber - 1) {
            view.go(to: page)
        }
        view.autoScales = true
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = document
        if let page = document.page(at: pageNumber - 1) {
            nsView.go(to: page)
        }
    }
} 
