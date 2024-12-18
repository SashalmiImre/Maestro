//
//  DropView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 13/12/2024.
//

import SwiftUI

struct DropView: View {
    @Binding var publication: Publication?
    @Binding var error: Error?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray)
                .padding(50)
            
            VStack {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                
                Text("Húzza ide a mappát")
                    .font(.headline)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    self.error = DropView.Errors.invalidURL
                    return
                }
                
                // Publikáció létrehozása
                do {
                    self.publication = try Publication(folderURL: url)
                } catch {
                    self.error = DropView.Errors.failedToCreatePublication
                }
            }
        }
    }
}

extension DropView {
    enum Errors: String, Error {
        case invalidURL = "Érvénytelen URL cím!"
        case failedToCreatePublication = "Nem sikerült a publikációt létrehozni!"
    }
}


