//
//  ContentView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//

import SwiftUI

struct ContentView: View {
    @State private var publication: Publication?
    @State private var isLoading = false
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let publication = publication {
                // Ha van érvényes publikáció, megjelenítjük a layoutokat
                LayoutsView(publication: publication)
            } else {
                // Ha nincs publikáció, várjuk a drag & drop-ot
                DropView(publication: $publication, error: $error)
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

//#Preview {
//    ContentView()
//}
