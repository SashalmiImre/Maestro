//
//  ContentView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager: PublicationManager = .init()
    @State private var error: Error?
    @State private var temporaryPageNumber: Int = 1
    
    // Add formatter for columns
    private let columnsFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimum = 1
        formatter.maximum = 10
        formatter.allowsFloats = false
        return formatter
    }()
    
    // Add page number formatter
    private var pageFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.minimum = 1
        formatter.maximum = NSNumber(value: manager.maxPageNumber)
        formatter.allowsFloats = false
        return formatter
    }
    
    init() {
        _temporaryPageNumber = State(initialValue: 1)
    }
    
    var body: some View {
        Group {
            if manager.publication == nil {
                // Ha nincs publikáció, várjuk a drag & drop-ot
                DropView(error: $error)
                
            } else {
                // Ha van érvényes publikáció, megjelenítjük a layoutokat
                LayoutsView()
                    .toolbar {
                        // Bal oldali elemek
                        ToolbarItemGroup(placement: .principal) {
                            HStack {
                                // Add page navigation controls
                                pageNavigationControls
                                Divider()
                                
                                // Zoom csúszka
                                zoomControls
                                Divider()
                                
                                // Maximum oldalszám beállítás
                                maxPageControls
                                Divider()
                                
                                // Oszlopok beállítás
                                columnsControls
                            }
                        }
                                                
                        // Jobb oldali elemek
                        ToolbarItemGroup(placement: .primaryAction) {
                            HStack {
                                Divider()

                                // Frissítés gomb
                                Button {
                                    Task {
                                        await manager.refresh()
                                    }
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                }
                                
                                // Export
                                Button {
                                    Task {
                                        manager.isExporting = true
                                    }
                                } label: {
                                    Image(systemName: "square.and.arrow.up")
                                }
                                
                                // Mód kapcsoló
                                Toggle(isOn: $manager.isEditMode) {
                                    Image(systemName: manager.isEditMode ? "lock.open" : "lock")
                                }
                                .help(manager.isEditMode ? "Szerkesztés mód" : "Olvasás mód")
                            }
                        }
                    }
            }
        }
        .environmentObject(manager)
        .frame(minWidth: 800, minHeight: 600)
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
            Image(systemName: "doc.badge.ellipsis")
                .help("Maximum oldalszám")
            TextField("", text: Binding(
                get: { String(manager.maxPageNumber) },
                set: { if let value = Int($0) { manager.maxPageNumber = value } }
            ))
            .fixedSize()
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    private var columnsControls: some View {
        HStack {
            Image(systemName: "rectangle.split.3x1")
                .help("Oszlopok száma")
            TextField("", value: $manager.layoutColumns, formatter: columnsFormatter)
                .fixedSize()
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    // Updated page navigation controls
    private var pageNavigationControls: some View {
        HStack {
            Button(action: {
                manager.currentPageNumber -= 1
            }) {
                Image(systemName: "chevron.left")
            }
            .disabled(manager.currentPageNumber <= 1)
            
            TextField("", value: $temporaryPageNumber, formatter: pageFormatter)
                .fixedSize()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .multilineTextAlignment(.center)
                .onSubmit {
                    manager.currentPageNumber = temporaryPageNumber
                }
                .onChange(of: manager.currentPageNumber) { newValue in
                    temporaryPageNumber = newValue
                }
            
            Button(action: {
                manager.currentPageNumber += 1
            }) {
                Image(systemName: "chevron.right")
            }
            .disabled(manager.currentPageNumber >= manager.maxPageNumber)
        }
    }
}
