//
//  DropZoneView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 05/12/2024.
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @Binding var folderPath: String?
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [10]))
                .foregroundColor(.gray)
            
            VStack {
                Image(systemName: "folder.badge.plus")
                    .font(.system(size: 40))
                Text("Húzza ide a mappát")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { (urlData, error) in
                if let urlData = urlData as? Data,
                   let path = String(data: urlData, encoding: .utf8),
                   let url = URL(string: path) {
                    DispatchQueue.main.async {
                        folderPath = url.path
                    }
                }
            }
            return true
        }
    }
}
