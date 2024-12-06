//
//  ErrorView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 05/12/2024.
//

import SwiftUI

struct ErrorView: View {
    let error: Error
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.red)
            Text("Hiba történt")
                .font(.headline)
            Text(error.localizedDescription)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}
