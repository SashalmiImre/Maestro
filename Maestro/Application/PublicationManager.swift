//
//  PublicationManager.swift
//  Maestro
//
//  Created by Sashalmi Imre on 21/12/2024.
//

import SwiftUI
import Algorithms

/// Az alkalmazás állapotkezelője, amely felelős a kiadvány és annak lehetséges
/// oldalelrendezéseinek kezeléséért.
@MainActor
class PublicationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var publication: Publication?
    @Published private(set) var layouts: Set<Layout> = .init()
    @Published var selectedLayoutIndex: Int = 0
    @Published var maxPageNumber: Int = 8
    @Published var zoomLevel: Double = ZoomSettings.initial
    @Published var isEditMode: Bool = false
    @Published var isExporting = false
    @Published var layoutColumns: Int = 5
    @Published var currentPageNumber: Int = 1
    

    // MARK: - Private Properties
    
//    private var availablePDFs: [URL] = []
//    private var availableInddFiles: [URL] = []
    
    // MARK: - Initialization
    
    /// Inicializálja az állapotkezelőt és legenerálja az első layout-okat
    init() {
        Task {
            await refresh()
        }
    }
    
    
    // MARK: - Computed properties
    
    /// A maximális oldalszám, ami befogadja az összes oldalt és osztható 8-cal,
    /// plusz 4 oldal a borítóhoz
    /// - Returns: A legkisebb 8-cal osztható szám (a belső oldalakra), ami nagyobb vagy egyenlő
    /// mint a pageCount, plusz 4 oldal a borítóhoz
    var printingPageCount: Int {
        let coverPageCount = 4
        let pageCount = (selectedLayout?.maxPageNumber ?? 8) - coverPageCount
        let remainder = pageCount % 8
        let innerPages = remainder == 0 ? pageCount : pageCount + (8 - remainder)
        return innerPages + coverPageCount
    }
    
    var selectedLayout: Layout? {
        Array(layouts)[safe: selectedLayoutIndex]
    }
    
    
    // MARK: - Refresh/reset

    private func reset() async {
        layouts.removeAll()
        selectedLayoutIndex = 0
        await publication?.refreshArticles()
//        availablePDFs = []
//        availableInddFiles = []
        maxPageNumber = 8
    }
    
    func refresh() async {
        await reset()
        await publication?.refreshArticles()
        maxPageNumber = printingPageCount
    }


    
    // MARK: - Zoom constans

    struct ZoomSettings {
        static let range = 0.1...2.1
        static let step = 0.2
        static let initial = 0.3
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
