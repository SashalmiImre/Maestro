import SwiftUI

struct LayoutsView: View {
    let layouts: [Layout]
    
    var body: some View {
        TabView {
            ForEach(Array(layouts.enumerated()), id: \.offset) { index, layout in
                LayoutView(layout: layout)
                    .tabItem {
                        Text("Variáció \(index + 1)")
                    }
            }
        }
        .frame(minWidth: 800, minHeight: 600)  // Minimum ablakméret
        .padding()
    }
} 