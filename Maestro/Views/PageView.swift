import SwiftUI
import PDFKit

struct PageView: View {
    let document: PDFKit.PDFDocument?
    let pageNumber: Int
    
    var body: some View {
        ZStack {
            if let document = document {
                PDFPageView(document: document, pageNumber: pageNumber)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                Text("\(pageNumber)")
                    .font(.system(size: 32))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(210/297, contentMode: .fit) // A4 arány
    }
} 
