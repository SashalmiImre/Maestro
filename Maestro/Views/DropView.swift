//
//  DropView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 13/12/2024.
//

import SwiftUI

struct DropView: View {
    @EnvironmentObject var manager: PublicationManager
    @Binding var error: Error?
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                .foregroundColor(.gray)
                .padding(50)
            
            VStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 40))
                    
                    Text("Húzza ide a mappát")
                        .font(.headline)
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            handleDrop(providers: providers)
            return true
        }
    }
    
    @MainActor
    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        isLoading = true
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
            if let error = error {
                self.error = error
                self.isLoading = false
                return
            }
            
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                self.error = DropView.Errors.invalidURL
                self.isLoading = false
                return
            }
            
            Task { @MainActor in
                do {
                    let pub = try await Publication(folderURL: url)
                    manager.publication = pub
                    await manager.refreshLayouts()
                } catch {
                    self.error = DropView.Errors.failedToCreatePublication
                }
                self.isLoading = false
            }
        }
    }
}

extension DropView {
    enum Errors: LocalizedError {
        case invalidURL
        case failedToCreatePublication
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return NSLocalizedString(
                    "Érvénytelen URL cím!",
                    comment: "Invalid URL error message"
                )
            case .failedToCreatePublication:
                return NSLocalizedString(
                    "Nem sikerült a publikációt létrehozni!",
                    comment: "Failed to create publication error message"
                )
            }
        }
    }
}
