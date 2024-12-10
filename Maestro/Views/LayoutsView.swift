import SwiftUI
import PDFKit

struct LayoutsView: View {
    @StateObject private var viewModel: LayoutsViewModel
    
    init(publication: Publication) {
        _viewModel = StateObject(wrappedValue: LayoutsViewModel(publication: publication))
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedLayoutIndex) {
            ForEach(Array(viewModel.layouts.enumerated()), id: \.offset) { index, layout in
//                LayoutView(layout: layout)
                DraggableLayoutView(layout: layout)
                    .tabItem {
                        Text("Layout \(index + 1)")
                    }
                    .tag(index)
            }
        }
        .navigationTitle("Layoutok")
        .toolbar {
            Button(action: viewModel.refreshLayouts) {
                Image(systemName: "arrow.clockwise")
            }
        }
    }
}

//#Preview {
//    LayoutsView(publication: .previewValue)
//} 
