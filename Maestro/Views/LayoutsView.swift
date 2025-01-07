import SwiftUI
import PDFKit

struct LayoutsView: View {
    @EnvironmentObject var manager: PublicationManager
    @State private var exportInProgress = false
    @State private var maxPageNumberText = ""
    
    // MARK: - Layout Content
    
    @ViewBuilder
    private func layoutView(for layout: Layout, at index: Int) -> some View {
        LayoutView(layout: layout)
            .tabItem {
                let layoutVersionCharacter = Character(UnicodeScalar(index + 65)!)
                Text("\(layoutVersionCharacter) - elrendezés")
            }
            .tag(index)
    }
    
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $manager.selectedLayoutIndex) {
            ForEach(Array(manager.layouts.enumerated()), id: \.offset) { index, layout in
                layoutView(for: layout, at: index)
                    .environmentObject(manager)
            }
        }
        .padding()
        .navigationTitle(manager.publication?.name ?? "Név nélkül")
//        .onChange(of: manager.layouts ?? []) { _, newLayouts in
//            // Update selected index if needed
//            if newLayouts.count <= manager.selectedLayout {
//                manager.selectedLayout = max(0, newLayouts.count - 1)
//            }
//
//            // Update max page number if needed
//            let newMax = newLayouts.first.map { layout in
//                max(
//                    layout.pages.map(\.pageNumber).max() ?? 0,
//                    layout.pageCount
//                )
//            } ?? 0
//            maxPageNumberText = String(newMax)
//        }
    }
}

//#Preview {
//    LayoutsView(publication: .previewValue)
//}
