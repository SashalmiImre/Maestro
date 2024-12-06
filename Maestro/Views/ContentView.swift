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
    @State private var errorMessage: String?
    
    var body: some View {
        Group {
            if let publication = publication {
                // Ha van érvényes publikáció, megjelenítjük a layoutokat
                LayoutsView(layouts: publication.getLayouts())
            } else {
                // Ha nincs publikáció, várjuk a drag & drop-ot
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(.gray)
                        .frame(width: 400, height: 200)
                    
                    VStack(spacing: 16) {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(1.5)
                        }
                        
                        Text(errorMessage ?? "Húzd ide a publikáció mappáját")
                            .foregroundColor(errorMessage != nil ? .red : .primary)
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        isLoading = true
        errorMessage = nil
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Hiba: \(error.localizedDescription)"
                    self.isLoading = false
                    return
                }
                
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    self.errorMessage = "Érvénytelen URL"
                    self.isLoading = false
                    return
                }
                
                // Publikáció létrehozása
                if let publication = Publication(folderURL: url) {
                    self.publication = publication
                } else {
                    self.errorMessage = "Nem sikerült létrehozni a publikációt"
                }
                
                self.isLoading = false
            }
        }
    }
}

#Preview {
    ContentView()
}
