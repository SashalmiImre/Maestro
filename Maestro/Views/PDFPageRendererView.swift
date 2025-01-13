////
////  PDFPageRendererView.swift
////  Maestro
////
////  Created by Sashalmi Imre on 14/12/2024.
////

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
    
    @MainActor static func getCachedImage(key: NSString) -> NSImage? {
        return cache.object(forKey: key)
    }
    
    @MainActor static func setCachedImage(_ image: NSImage, forKey key: NSString) {
        cache.setObject(image, forKey: key)
    }
    
    // Add task cancellation support
    @State private var renderTask: Task<Void, Never>? = nil
    
    var pdfPage: PDFPage
    var displayBox: PDFDisplayBox = .trimBox
    
    // Cache-eljük a méreteket
    private var pageSize: CGSize {
        let bounds = pdfPage.bounds(for: displayBox)
        return CGSize(width:  round(bounds.width * manager.zoomLevel),
                      height: round(bounds.height * manager.zoomLevel))
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if manager.isExporting {
                // Use a simple PDF rendering for export
                PDFExportView(pdfPage: pdfPage, displayBox: displayBox, size: pageSize)
                    .environmentObject(manager)
            } else {
                // Regular cached rendering
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
                .onChange(of: manager.zoomLevel) { newScale in
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
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func renderImage() async {
        let key = "\(pdfPage.hash)_\(manager.zoomLevel)_\(displayBox.rawValue)" as NSString
        
        // Check cache on MainActor
        if let cachedImage = PDFPageRendererView.getCachedImage(key: key) {
            pageImage = Image(nsImage: cachedImage)
            isLoading = false
            return
        }
        
        do {
            try await Task.sleep(for: .milliseconds(50))  // Small delay for smoother transitions
            
            let bounds = pdfPage.bounds(for: displayBox)
            let size = CGSize(width: bounds.width * manager.zoomLevel,
                              height: bounds.height * manager.zoomLevel)
            
            // Check if size is valid
            guard size.width > 0 && size.height > 0 else {
                return
            }
            
            let scale = manager.zoomLevel
            
            // Render in background using CGImage
            let cgImage = try await Task.detached(priority: .userInitiated) { () -> CGImage in
                let image = NSImage(size: size)
                
                // Check if size is valid before locking focus
                guard size.width > 0 && size.height > 0 else {
                    throw NSError(domain: "PDFRendering", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid image size"])
                }
                
                image.lockFocus()
                
                if let context = NSGraphicsContext.current?.cgContext {
                    context.scaleBy(x: scale, y: scale)
                    await pdfPage.draw(with: displayBox, to: context)
                }
                
                image.unlockFocus()
                
                guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                    throw NSError(domain: "PDFRendering", code: -1)
                }
                
                return cgImage
            }.value
            
            if Task.isCancelled { return }
            
            // Convert CGImage to NSImage on MainActor
            let nsImage = NSImage(cgImage: cgImage, size: size)
            PDFPageRendererView.setCachedImage(nsImage, forKey: key)
            pageImage = Image(nsImage: nsImage)
            isLoading = false
            previousImage = nil  // Töröljük az előző képet, ha az új elkészült
        } catch {
            print("Rendering error: \(error)")
        }
    }
}

struct PDFExportView: View {
    @EnvironmentObject var manager: PublicationManager
    
    var pdfPage: PDFPage
    var displayBox: PDFDisplayBox
    var size: CGSize
    
    var body: some View {
        // Get cached image key
        let key = "\(pdfPage.hash)_\(manager.zoomLevel)_\(displayBox.rawValue)" as NSString

        // Use cached image if available, otherwise generate and cache
        if let cachedImage = PDFPageRendererView.getCachedImage(key: key) {
            Image(nsImage: cachedImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
        } else {
            let nsImage = generateImage()
            
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size.width, height: size.height)
        }
    }
    
    // MARK: - Private Methods
    
    private func generateImage() -> NSImage {
        let key = "\(pdfPage.hash)_\(manager.zoomLevel)_\(displayBox.rawValue)" as NSString

        let bounds = pdfPage.bounds(for: displayBox)
        let scale = manager.zoomLevel
        
        // Create new image with proper size
        let nsImage = NSImage(size: size)
        nsImage.lockFocus()
        
        // Draw PDF into the image context
        if let context = NSGraphicsContext.current?.cgContext {
            context.scaleBy(x: scale, y: scale)
            pdfPage.draw(with: displayBox, to: context)
        }
        
        nsImage.unlockFocus()
        PDFPageRendererView.setCachedImage(nsImage, forKey: key)
        return nsImage
    }
}
