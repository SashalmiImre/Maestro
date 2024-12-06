//
//  ContentView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//

import SwiftUI
import PDFKit

struct ContentView: View {
    @State private var folderPath: String?
    @State private var isProcessing = false
    @State private var layouts: [LayoutVersion] = []
    @State private var error: Error?
    @State private var selectedLayout: LayoutVersion?
    @State private var isDatabaseBuilding = false
    
    var body: some View {
        VStack {
            if let error = error {
                ErrorView(error: error)
            } else if isDatabaseBuilding {
                ProgressView("Adatbázis felépítése...")
                    .progressViewStyle(.circular)
            } else if !layouts.isEmpty {
                TabView(selection: $selectedLayout) {
                    ForEach(layouts) { layout in
                        LayoutPreviewView(layout: layout)
                            .tabItem {
                                Text("Verzió \(layout.label)")
                            }
                            .tag(layout as LayoutVersion?)
                    }
                }
                .frame(minWidth: 800, minHeight: 600)
                
                if let layout = selectedLayout {
                    Button("Exportálás") {
                        Task {
                            await exportLayout(layout)
                        }
                    }
                    .disabled(isProcessing)
                }
            } else if let path = folderPath {
                ProcessingView(folderPath: path, isProcessing: $isProcessing)
                    .task {
                        await processFolder(path)
                    }
            } else {
                DropZoneView(folderPath: $folderPath)
            }
        }
        .padding()
        .onChange(of: folderPath) { oldValue, newValue in
            if let path = newValue {
                Task {
                    await buildDatabase(for: path)
                }
            }
        }
    }
    
    private func buildDatabase(for path: String) async {
        isDatabaseBuilding = true
        do {
            try await DatabaseService.buildDatabase(for: URL(filePath: path))
        } catch {
            self.error = error
        }
        isDatabaseBuilding = false
    }
    
    private func processFolder(_ path: String) async {
        isProcessing = true
        do {
            let documents = try await PDFProcessorService.findPDFFiles(
                in: URL(filePath: path)
            )
            layouts = LayoutManager.createLayouts(from: documents)
            selectedLayout = layouts.first
        } catch {
            self.error = error
        }
        isProcessing = false
    }
    
    private func exportLayout(_ layout: LayoutVersion) async {
        isProcessing = true
        do {
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.jpeg]
            savePanel.nameFieldStringValue = "layout_\(layout.label).jpg"
            
            if await savePanel.beginSheetModal(for: NSApp.keyWindow!) == .OK,
               let url = savePanel.url {
                try await ExportService.exportLayout(layout, to: url)
            }
        } catch {
            self.error = error
        }
        isProcessing = false
    }
}

#Preview {
    ContentView()
}
