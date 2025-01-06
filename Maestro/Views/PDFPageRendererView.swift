//
//  PDFPageRendererView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 14/12/2024.
//

import SwiftUI
import PDFKit

/// A PDFPage lusta betöltését és cache-elését végző nézet
struct PDFPageRendererView: View {
    @EnvironmentObject var manager: PublicationManager
    
    // MARK: - Properties
    
    @State private var isLoading: Bool = true
    @State private var pageImage: Image? = nil
    @State private var previousImage: Image? = nil  // Előző kép megtartása
    // Cache-t MainActor-on tároljuk
    @MainActor private static var cache = NSCache<NSString, NSImage>()
    
    // Add task cancellation support
    @State private var renderTask: Task<Void, Never>? = nil
    
    var pdfPage: PDFPage
    var displayBox: PDFDisplayBox = .trimBox
    
    // Cache-eljük a méreteket
    private var pageSize: CGSize {
        let bounds = pdfPage.bounds(for: displayBox)
        return CGSize(width: bounds.width * manager.zoomLevel,
                      height: bounds.height * manager.zoomLevel)
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if let pageImage = pageImage {
                pageImage
                    .resizable()  // Hozzáadjuk a resizable módosítót
                    .aspectRatio(contentMode: .fill)
            } else if let previousImage = previousImage {
                // Mutassuk az előző képet, amíg az új nem generálódik
                previousImage
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .animation(.easeInOut(duration: 0.2), value: pageImage != nil)
        .task {
            await renderImage()
        }
        .onChange(of: manager.zoomLevel) { oldScale, newScale in
            // Mentsük el az előző képet
            previousImage = pageImage
            // Cancel any ongoing rendering
            renderTask?.cancel()
            // Start new rendering
            renderTask = Task {
                await renderImage()
            }
        }
        .onDisappear {
            // Cancel rendering if view disappears
            renderTask?.cancel()
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func renderImage() async {
        let key = "\(pdfPage.hash)_\(manager.zoomLevel)_\(displayBox.rawValue)" as NSString
        
        // Check cache on MainActor
        if let cachedImage = PDFPageRendererView.cache.object(forKey: key) {
            pageImage = Image(nsImage: cachedImage)
            isLoading = false
            return
        }
        
        do {
            try await Task.sleep(for: .milliseconds(50))  // Small delay for smoother transitions
            
            let bounds = pdfPage.bounds(for: displayBox)
            let size = CGSize(width: bounds.width * manager.zoomLevel,
                              height: bounds.height * manager.zoomLevel)
            let scale = manager.zoomLevel
            
            // Render in background using CGImage
            let cgImage = try await Task.detached(priority: .userInitiated) { () -> CGImage in
                // Új NSImage létrehozása a megfelelő mérettel
                let image = NSImage(size: size)
                image.lockFocus()
                
                // PDF rajzolása az NSGraphicsContext-be
                if let context = NSGraphicsContext.current?.cgContext {
                    context.scaleBy(x: scale, y: scale)
                    await pdfPage.draw(with: displayBox, to: context)
                }
                
                image.unlockFocus()
                
                // NSImage konvertálása CGImage-é
                guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    throw NSError(domain: "PDFRendering", code: -1)
                }
                
                return cgImage
            }.value
            
            if Task.isCancelled { return }
            
            // Convert CGImage to NSImage on MainActor
            let nsImage = NSImage(cgImage: cgImage, size: size)
            PDFPageRendererView.cache.setObject(nsImage, forKey: key)
            pageImage = Image(nsImage: nsImage)
            isLoading = false
            previousImage = nil  // Töröljük az előző képet, ha az új elkészült
        } catch {
            print("Rendering cancelled or failed: \(error)")
        }
    }
}
