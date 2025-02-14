import SwiftUI
import PDFKit

struct ContentSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct LayoutsView: View {
    @StateObject private var context: LayoutViewContext = .init()
    @EnvironmentObject var manager: PublicationManager
    @State private var exportInProgress = false
    
    var body: some View {
        TabView(selection: $manager.selectedLayoutIndex) {
            ForEach(Array(manager.layouts.enumerated()), id: \.offset) { index, layout in
                LayoutContent(layout: layout, index: index)
                    .environmentObject(manager)
                    .environmentObject(context)
            }
        }
        .padding()
        .navigationTitle(manager.publication?.name ?? "Név nélkül")
        .focusedSceneObject(context)
    }
}

struct LayoutContent: View {
    @EnvironmentObject var context: LayoutViewContext
    @EnvironmentObject var manager: PublicationManager
    
    let layout: Layout
    let index: Int
    
    private var spacing: CGFloat {
        80 * manager.zoomLevel
    }
    
    private var horizontalPadding: CGFloat {
        let windowWidth = NSScreen.main?.frame.width ?? 1000
        return windowWidth / 4
    }
    
    private var verticalPadding: CGFloat {
        let windowHeight = NSScreen.main?.frame.height ?? 800
        return windowHeight / 4
    }
    
    var body: some View {
        GeometryReader { scrollViewGeometry in
            ScrollViewReader { proxy in
                ScrollView([.horizontal, .vertical]) {
                    LayoutView(layout: layout)
                        .environmentObject(manager)
                        .environmentObject(context)
                        .padding(.horizontal, horizontalPadding)
                        .padding(.vertical, verticalPadding)
                        .onChange(of: manager.currentPageNumber) { _, targetPageNumber in
                            let pageID = "Page\(targetPageNumber)"
                            withAnimation {
                                proxy.scrollTo(pageID, anchor: .center)
                            }
                        }
                }
                .onChange(of: scrollViewGeometry.size) { _, newSize in
                    context.scrollViewAvaiableSize = newSize
                    print("ScrollView available size: \(newSize)")
                }
                .onAppear {
                    context.scrollViewProxy = proxy
                    context.scrollViewAvaiableSize = scrollViewGeometry.size
                }
            }
        }
        .tabItem {
            let layoutVersionCharacter = Character(UnicodeScalar(index + 65)!)
            Text("\(layoutVersionCharacter) - elrendezés")
        }
        .tag(index)
    }
}
