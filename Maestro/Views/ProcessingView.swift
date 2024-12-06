import SwiftUI

struct ProcessingView: View {
    let folderPath: String
    @Binding var isProcessing: Bool
    
    var body: some View {
        VStack {
            if isProcessing {
                ProgressView()
                    .scaleEffect(2)
                    .padding(.bottom, 20)
                Text("PDF fájlok feldolgozása...")
                    .font(.headline)
                Text(folderPath)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
} 
