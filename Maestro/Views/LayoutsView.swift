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
    
    // MARK: - Helper Views
    
    private var zoomControls: some View {
        HStack {
            Image(systemName: "minus.magnifyingglass")
            Slider(
                value: $manager.zoomLevel,
                in: PublicationManager.ZoomSettings.range,
                step: PublicationManager.ZoomSettings.step
            )
            .frame(width: 100)
            Image(systemName: "plus.magnifyingglass")
        }
    }
    
    private var maxPageControls: some View {
        HStack {
            Text("Maximum oldalszám:")
                .foregroundColor(.secondary)
            TextField("", text: Binding(
                get: { String(manager.maxPageNumber) },
                set: { if let value = Int($0) { manager.maxPageNumber = value } }
            ))
            .frame(width: 60)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $manager.selectedLayout) {
            let layouts = Array(Array(manager.layouts).enumerated())
            ForEach(layouts, id: \.offset) { index, layout in
                layoutView(for: layout, at: index)
                    .environmentObject(manager)
            }
        }
        .padding()
        .navigationTitle(manager.publication?.name ?? "Név nélkül")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                HStack {
                    Toggle(isOn: $manager.isEditMode) {
                        Image(systemName: manager.isEditMode ? "lock.open" : "lock")
                    }
                    .help(manager.isEditMode ? "Szerkesztés mód" : "Olvasás mód")
                    
                    Divider()
                    
                    zoomControls
                    
                    Divider()
                    
                    maxPageControls
                    
                    Button {
                        Task {
                            await manager.refresh()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                }
            }
        }
        .onChange(of: manager.layouts ?? []) { _, newLayouts in
            // Update selected index if needed
            if newLayouts.count <= manager.selectedLayout {
                manager.selectedLayout = max(0, newLayouts.count - 1)
            }
            
            // Update max page number if needed
            let newMax = newLayouts.first.map { layout in
                max(
                    layout.pages.map(\.pageNumber).max() ?? 0,
                    layout.pageCount
                )
            } ?? 0
            maxPageNumberText = String(newMax)
        }
    }
}

//#Preview {
//    LayoutsView(publication: .previewValue)
//}
