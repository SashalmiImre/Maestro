import SwiftUI

struct MainMenu: Commands {
    @FocusedObject private var manager: PublicationManager?
    @FocusedObject private var context: LayoutViewContext?
        
    var body: some Commands {
        CommandGroup(before: .toolbar) {
            Menu("Zoom") {
                Button("Zoom to Fit Current Page") {
                    Task {
                        await zoomToFitCurrentPage()
                    }
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Button("Zoom to Fit Layout Width") {
                    Task {
                        await zoomToFitLayoutWidth()
                    }
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Zoom to Fit Current Page Pair") {
                    Task {
                        await zoomToFitCurrentPagePair()
                    }
                }
                .keyboardShortcut("3", modifiers: .command)
            }
        }
    }
    
    private func zoomToFitCurrentPage() async {
        guard let manager = manager, let context = context else { return }
        let availableSize = context.scrollViewAvaiableSize
        let spacing = 80 * manager.zoomLevel
        let availableWidth = availableSize.width - spacing * 2
        let availableHeight = availableSize.height - spacing * 2
        
        if let rect = manager.layouts.first?.maxPageSizes[.trimBox] {
            let maxPageSize = rect.size
            let zoomX = availableWidth / (maxPageSize.width * 2)
            let zoomY = availableHeight / maxPageSize.height
            await MainActor.run {
                withAnimation {
                    manager.zoomLevel = min(zoomX, zoomY)
                    context.scrollViewProxy?.scrollTo("Page\(manager.currentPageNumber)")
                }
            }
        }
    }
    
    private func zoomToFitLayoutWidth() async {
        guard let manager = manager, let context = context else { return }
        if let rect = manager.layouts.first?.maxPageSizes[.trimBox] {
            let maxPageSize = rect.size
            let spacing = 80 * manager.zoomLevel
            let totalWidth = (maxPageSize.width * 2.0 * CGFloat(manager.layoutColumns)) + (spacing * CGFloat(manager.layoutColumns - 1))
            let availableSize = context.scrollViewAvaiableSize
            let availableWidth = availableSize.width - spacing * 2
            await MainActor.run {
                withAnimation {
                    manager.zoomLevel = max(0.1, availableWidth / totalWidth)
                }
            }
        }
    }
    
    private func zoomToFitCurrentPagePair() async {
        guard let manager = manager, let context = context else { return }
        if let rect = manager.layouts.first?.maxPageSizes[.trimBox] {
            let maxPageSize = rect.size
            let pagePairs = await manager.selectedLayout?.pagePairs(maxPageCount: manager.maxPageNumber) ?? []
            if let pagePair = pagePairs.first(where: { $0.coverage.contains(manager.currentPageNumber) }) {
                let spacing = 80 * manager.zoomLevel
                let pairWidth = maxPageSize.width * 2
                let availableSize = context.scrollViewAvaiableSize
                let availableWidth = availableSize.width - spacing * 2
                let availableHeight = availableSize.height - spacing * 2
                let zoomX = availableWidth / pairWidth
                let zoomY = availableHeight / maxPageSize.height
                await MainActor.run {
                    withAnimation {
                        manager.zoomLevel = max(0.1, min(zoomX, zoomY))
                        context.scrollViewProxy?.scrollTo("PagePair\(pagePair.coverage.lowerBound)")
                    }
                }
            }
        }
    }
}
