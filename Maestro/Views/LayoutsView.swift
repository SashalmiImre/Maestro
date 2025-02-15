import SwiftUI
import PDFKit

struct LayoutsView: View {
    @EnvironmentObject   var manager: PublicationManager
    @StateObject private var context: LayoutViewContext = .init()
    @State       private var exportInProgress = false
        
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
        .onChange(of: manager.selectedLayoutIndex) { _, _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    
                }
            }
        }
    }
}

struct LayoutContent: View {
    @EnvironmentObject var context: LayoutViewContext
    @EnvironmentObject var manager: PublicationManager
    @Environment(\.scrollViewProxy) private var scrollViewProxy
    
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
                        .background(
                            GeometryReader { geometry in
                                Color.clear.preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geometry.frame(in: .named("scroll"))
                                )
                            }
                        )
                        .onChange(of: manager.currentPageNumber) { _, targetPageNumber in
                            let pageID = "Page\(targetPageNumber)"
                            withAnimation {
                                proxy.scrollTo(pageID, anchor: .center)
                            }
                        }
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    Task { @MainActor in
                        context.scrollViewPosition = value
                        withAnimation {
                            proxy.scrollTo(value, anchor: .top)
                        }
                    }
                }
                .onAppear {
                    context.scrollViewProxy = proxy
                    context.scrollViewAvaiableSize = scrollViewGeometry.size
                    withAnimation {
                        proxy.scrollTo(context.scrollViewPosition, anchor: .top)
                    }
                }
                .onChange(of: scrollViewGeometry.size) { _, newSize in
                    context.scrollViewAvaiableSize = newSize
                }
                .environment(\.scrollViewProxy, proxy)
            }
        }
        .tabItem {
            let layoutVersionCharacter = Character(UnicodeScalar(index + 65)!)
            Text("\(layoutVersionCharacter) - elrendezés")
        }
        .tag(index)
    }
}


// MARK: - Preference keys

struct ContentSizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static let defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        print("value: \(value)")
//        value = nextValue()
        print("value: \(value)")
        print("-----")
    }
}

private struct ScrollViewProxyKey: @preconcurrency EnvironmentKey {
    @MainActor static let defaultValue: ScrollViewProxy? = nil
}

extension EnvironmentValues {
    var scrollViewProxy: ScrollViewProxy? {
        get { self[ScrollViewProxyKey.self] }
        set { self[ScrollViewProxyKey.self] = newValue }
    }
}

extension CGRect: @retroactive Hashable {}
