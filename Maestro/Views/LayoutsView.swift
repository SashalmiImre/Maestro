import SwiftUI
import PDFKit

struct LayoutsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedLayoutIndex = 0
    
    @State private var maxPageNumberText: String = ""
    @State private var userDefinedMaxPage: Int?
    @State private var isEditMode: Bool = false
    
    // Grouped related state variables
    private struct ZoomSettings {
        static let range = 0.1...1.0
        static let step = 0.15
        static let initial = 0.2
    }
    
    @State private var zoomLevel: Double = ZoomSettings.initial
    
    // MARK: - Layout Content
    
    private func layoutView(for layout: Layout, at index: Int) -> some View {
        LayoutView(
            layout: layout,
            userDefinedMaxPage: userDefinedMaxPage,
            isEditMode: isEditMode,
            pdfScale: CGFloat(zoomLevel)
        )
        .tabItem {
            Text("Layout \(index + 1)")
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
        TabView(selection: $selectedLayoutIndex) {
            ForEach(Array(appState.layouts.enumerated()), id: \.offset) { index, layout in
                layoutView(for: layout, at: index)
            }
        }
        .padding()
        .navigationTitle("Elrendezések")
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
                        appState.refreshLayouts()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .onAppear {
            if maxPageNumberText.isEmpty {
                let initialMax = appState.layouts.first.map { layout in
                    max(
                        layout.pages.map(\.pageNumber).max() ?? 0,
                        layout.pageCount
                    )
                } ?? 0
                maxPageNumberText = String(initialMax)
            }
        }
    }
}

//#Preview {
//    LayoutsView(publication: .previewValue)
//}
