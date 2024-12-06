import SwiftUI
import PDFKit

struct LayoutPreviewView: View {
    let layout: LayoutVersion
    
    var body: some View {
        ScrollView {
            VStack(spacing: ExportService.rowSpacing) {
                ForEach(layout.pagePairs) { pair in
                    HStack(spacing: ExportService.pairSpacing) {
                        PagePairView(pair: pair)
                    }
                }
            }
            .padding()
        }
    }
}
