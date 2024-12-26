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
            }
        }
        .environmentObject(manager)
        .frame(minWidth: 800, minHeight: 600)
    }
}

//#Preview {
//    ContentView()
//}
