import SwiftUI
import PDFKit

struct LayoutsView: View {
    @EnvironmentObject var manager: PublicationManager
    
    @State private var maxPageNumberText: String = ""
    @State private var userDefinedMaxPage: Int?
    @State private var isEditMode: Bool = false
    
    // Grouped related state variables
    private struct ZoomSettings {
        static let range = 0.1...2.0
        static let step = 0.2
        static let initial = 0.2
    }
    
    @State private var zoomLevel: Double = ZoomSettings.initial
    
    // Add layout change observer
    @State private var previousLayoutCount = 0
    
    // MARK: - Layout Content
    
    @ViewBuilder
    private func layoutView(for layout: Layout, at index: Int) -> some View {
        LayoutView(
            layout: layout,
            userDefinedMaxPage: userDefinedMaxPage,
            isEditMode: isEditMode,
            pdfScale: CGFloat(zoomLevel)
        )
        .tabItem {
            let layoutVersionCharacter = Character(UnicodeScalar(index + 65)!)
            Text("\(layoutVersionCharacter) - elrendezés")
        }
        .tag(index)
    }
    
    // MARK: - Helper Views
    
    private var zoomControls: some View {
        HStack {
            Image(systemName: "minus.magnifyingglass")
            Slider(
                value: $zoomLevel,
                in: ZoomSettings.range,
                step: ZoomSettings.step
            )
            .frame(width: 100)
            Image(systemName: "plus.magnifyingglass")
        }
    }
    
    private var maxPageControls: some View {
        HStack {
            Text("Maximum oldalszám:")
                .foregroundColor(.secondary)
            TextField("", text: $maxPageNumberText)
                .frame(width: 60)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onChange(of: maxPageNumberText) { _, newValue in
                    if let number = Int(newValue) {
                        userDefinedMaxPage = number
                    } else {
                        userDefinedMaxPage = nil
                    }
                }
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $manager.selectedLayoutIndex) {
            let layouts = Array(Array(manager.layouts ?? []).enumerated())
            ForEach(layouts, id: \.offset) { index, layout in
                layoutView(for: layout, at: index)
            }
        }
        .padding()
        .navigationTitle(manager.publication?.name ?? "Név nélkül")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack {
                    Toggle(isOn: $isEditMode) {
                        Image(systemName: isEditMode ? "lock.open" : "lock")
                    }
                    .help(isEditMode ? "Szerkesztés mód" : "Olvasás mód")
                    
                    Divider()
                    zoomControls
                    Divider()
                    maxPageControls
                    
                    Button {
                        Task {
                            await manager.refreshLayouts()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onChange(of: manager.layouts ?? []) { _, newLayouts in
            // Update selected index if needed
            if newLayouts.count <= manager.selectedLayoutIndex {
                manager.selectedLayoutIndex = max(0, newLayouts.count - 1)
            }
            
            // Update max page number if needed
            let newMax = newLayouts.first.map { layout in
                max(
                    layout.pages.map(\.pageNumber).max() ?? 0,
                    layout.pageCount
                )
            } ?? 0
            maxPageNumberText = String(newMax)
            previousLayoutCount = newLayouts.count
        }
        .task {
            if maxPageNumberText.isEmpty {
                let initialMax = manager.layouts?.first.map { layout in
                    max(
                        layout.pages.map(\.pageNumber).max() ?? 0,
                        layout.pageCount
                    )
                } ?? 0
                maxPageNumberText = String(initialMax)
                previousLayoutCount = manager.layouts?.count ?? 0
            }
        }
    }
}

//#Preview {
//    LayoutsView(publication: .previewValue)
//}
