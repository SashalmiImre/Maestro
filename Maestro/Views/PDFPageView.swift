import SwiftUI
import PDFKit

struct PDFPageView: View {
    let document: PDFKit.PDFDocument
    let pageNumber: Int
    
    var body: some View {
        PDFKitView(document: document, pageNumber: pageNumber)
    }
}


