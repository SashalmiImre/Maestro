import SwiftUI
import PDFKit

struct PagePairView: View {
    let pair: PagePair
    
    var body: some View {
        VStack {
            HStack {
                PageView(document: pair.leftDocument?.document, pageNumber: pair.leftPage)
                PageView(document: pair.rightDocument?.document, pageNumber: pair.rightPage)
            }
            .frame(width: 200, height: 150)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
