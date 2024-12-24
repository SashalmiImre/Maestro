//
//  ContentView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//

import SwiftUI

struct ContentView: View {
    @StateObject var appState: AppState = .init()
    @State private var error: Error?
    
    var body: some View {
        Group {
            if appState.publication == nil {
                // Ha nincs publikáció, várjuk a drag & drop-ot
                DropView(publication: $appState.publication, error: $error)

            } else {
                // Ha van érvényes publikáció, megjelenítjük a layoutokat
                LayoutsView()
                    .environmentObject(appState)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

//#Preview {
//    ContentView()
//}
