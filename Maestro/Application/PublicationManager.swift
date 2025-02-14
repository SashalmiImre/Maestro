//
//  PublicationManager.swift
//  Maestro
//
//  Created by Sashalmi Imre on 21/12/2024.
//

import SwiftUI
import Algorithms

@MainActor
class PublicationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published              var publication: Publication?
    @Published private(set) var layouts: Set<Layout> = .init()
    @Published              var selectedLayoutIndex: Int = 0
    @Published              var maxPageNumber: Int = 8
    @Published              var zoomLevel: Double = ZoomSettings.initial
    @Published              var isEditMode: Bool = false
    @Published              var isExporting = false
    @Published              var layoutColumns: Int = 5
    @Published              var currentPageNumber: Int = 1
    
    var selectedLayout: Layout? {
        Array(layouts)[safe: selectedLayoutIndex]
    }
    
    
    // MARK: - Refresh/reset

    private func reset() {
        layouts.removeAll()
        selectedLayoutIndex = 0
        maxPageNumber = 8
    }
    
    func refresh() async {
        guard let publication = publication else { return }

        reset()
        await publication.refreshArticles()
        layouts       = await publication.layoutCombinations
        maxPageNumber = await selectedLayout!.printingPageCount
    }

    
    // MARK: - Zoom constans

    struct ZoomSettings {
        static let range   = 0.1...2.1
        static let step    = 0.2
        static let initial = 0.3
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
