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
    
    var body: some View {
        Group {
            if manager.publication == nil {
                // Ha nincs publikáció, várjuk a drag & drop-ot
                DropView(error: $error)
                
            } else {
                // Ha van érvényes publikáció, megjelenítjük a layoutokat
                LayoutsView()
                    .toolbar(content: {
                        // Mód kapcsoló
                        ToolbarItem(placement: .primaryAction) {
                            Toggle(isOn: $manager.isEditMode) {
                                Image(systemName: manager.isEditMode ? "lock.open" : "lock")
                            }
                            .help(manager.isEditMode ? "Szerkesztés mód" : "Olvasás mód")
                            Divider()
                        }
                                                
                        // Zoom csúszka
                        ToolbarItem(placement: .primaryAction) {
                            zoomControls
                            Divider()
                        }
                        
                        // Maximum oldalszám beállítás
                        ToolbarItem(placement: .primaryAction) {
                            maxPageControls
                            Divider()
                        }
                        
                        // Frissítés gomb
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                Task {
                                    await manager.refresh()
                                }
                            } label: {
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    })
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
            Text("Maximum oldalszám:")
                .foregroundColor(.secondary)
            TextField("", text: Binding(
                get: { String(manager.maxPageNumber) },
                set: { if let value = Int($0) { manager.maxPageNumber = value } }
            ))
            .frame(width: 60)
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
}

//#Preview {
//    ContentView()
//}
