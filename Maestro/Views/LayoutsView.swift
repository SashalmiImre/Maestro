import SwiftUI
import PDFKit

struct LayoutsView: View {
    @StateObject private var publication: Publication
    @StateObject private var viewModel: LayoutsViewModel
    @AppStorage("maxPageNumberText") private var maxPageNumberText: String = ""
    @AppStorage("userDefinedMaxPage") private var userDefinedMaxPage: Int?
    @State private var isEditMode: Bool = false
    @State private var zoomLevel: Double = 0.2
    
    init(publication: Publication) {
        _publication = StateObject(wrappedValue: publication)
        _viewModel = StateObject(wrappedValue: LayoutsViewModel(publication: publication))
    }
    
    // MARK: - Layout Content
    
    private func layoutView(for layout: Layout, at index: Int) -> some View {
        LayoutView(
            layout: layout,
            userDefinedMaxPage: userDefinedMaxPage,
            isEditMode: isEditMode,
            pdfScale: CGFloat(zoomLevel)
        )
        .onAppear {
            Task {
                await publication.refreshArticles()
            }
        }
        .tabItem {
            Text("Layout \(index + 1)")
        }
        .tag(index)
    }
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $viewModel.selectedLayoutIndex) {
            ForEach(Array(viewModel.layouts.enumerated()), id: \.offset) { index, layout in
                layoutView(for: layout, at: index)
            }
        }
        .padding()
        .navigationTitle("Layoutok")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Toggle(isOn: $isEditMode) {
                    Image(systemName: isEditMode ? "lock.open" : "lock")
                }
                .help(isEditMode ? "Szerkesztés mód" : "Olvasás mód")
                
                Divider()
                
                HStack {
                    Image(systemName: "minus.magnifyingglass")
                    Slider(
                        value: $zoomLevel,
                        in: 0.1...1.0,
                        step: 0.15
                    )
                    .frame(width: 100)
                    Image(systemName: "plus.magnifyingglass")
                }
                
                Divider()
                
                HStack {
                    Text("Maximum oldalszám:")
                        .foregroundColor(.secondary)
                    TextField("", text: $maxPageNumberText)
                        .frame(width: 60)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: maxPageNumberText) { oldValue, newValue in
                            if let number = Int(newValue) {
                                userDefinedMaxPage = number
                            } else {
                                userDefinedMaxPage = nil
                            }
                        }
                }
                
                Button(action: viewModel.refreshLayouts) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .onAppear {
            if maxPageNumberText.isEmpty {
                let initialMax = viewModel.layouts.first.map { layout in
                    max(
                        layout.layoutPages.map(\.pageNumber).max() ?? 0,
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
