///
///  PageRendererView.swift
///  Maestro
///
///  Created by Sashalmi Imre on 14/12/2024.
///

import SwiftUI
@preconcurrency import PDFKit

/// A PDFPage lusta betöltését és cache-elését végző nézet
struct PageRendererView: View {
    @EnvironmentObject var manager: PublicationManager
    @EnvironmentObject var context: LayoutViewContext
    
    
    // MARK: - Propertyk
    
    @State private var pageImage: Image? = nil
    
    let pdfPage: PDFPage
    let displayBox: PDFDisplayBox = .trimBox
    
    
    // MARK: - Számított propertyk
    
    private var cacheKey: NSString {
        "\(pdfPage.hash)_\(manager.zoomLevel)_\(displayBox.rawValue)" as NSString
    }
    
    private var pageSize: CGSize {
        let bounds = pdfPage.bounds(for: displayBox)
        return CGSize(width: round(bounds.width * manager.zoomLevel),
                      height: round(bounds.height * manager.zoomLevel))
    }
    
    
    // MARK: - Body
    
    var body: some View {
        
        if manager.isExporting {
            renderPDFPageSync()
        } else {
            Group {
                if let image = pageImage {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    ProgressView().progressViewStyle(.circular)
                }
            }
            .frame(width: pageSize.width, height: pageSize.height)
            .animation(.easeInOut(duration: 0.2), value: pageImage != nil)
            .task {
                await renderPDFPageAsync()
            }
            .onChange(of: manager.zoomLevel) { _, newValue in
                Task {
                    await renderPDFPageAsync()
                }
            }
        }
    }
    
    /// Alap PDF renderelő funkció, amely CGImage-t hoz létre
    nonisolated private func renderPDFPage(page: PDFPage, size: CGSize, zoom: CGFloat) -> CGImage? {
        autoreleasepool {
            // Létrehozunk egy bitmap-alapú CGContext-et
            guard let context = CGContext(
                data: nil,
                width: Int(size.width),
                height: Int(size.height),
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else {
                print("Nem sikerült a CGContext létrehozása")
                return nil
            }
            context.saveGState()
            
            // Renderelési paraméterek beállítása
            context.interpolationQuality = .high
            context.setAllowsAntialiasing(true)
            
            // Koordinátarendszer beállítása
            context.scaleBy(x: zoom, y: zoom)
            
            // PDF oldal renderelése
            page.draw(with: .trimBox, to: context)
            
            context.restoreGState()
            
            // CGImage létrehozása
            let cgImage = context.makeImage()
            return cgImage
        }
    }
    
    /// Szinkron funkció, amely SwiftUI Image-t hoz létre
    private func renderPDFPageSync() -> Image {
        guard let cgImage = renderPDFPage(page: pdfPage, size: pageSize, zoom: manager.zoomLevel) else {
            return Image(systemName: "xmark.rectangle.portrait")
        }
        return Image(decorative: cgImage, scale: 1.0)
    }
    
    /// Aszinkron funkció, amely SwiftUI Image-t hoz létre
    private func renderPDFPageAsync() async {
        let currentPage = pdfPage
        let currentSize = pageSize
        let currentZoom = manager.zoomLevel
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let cgImage = renderPDFPage(page: currentPage, size: currentSize, zoom: currentZoom) {
                    DispatchQueue.main.async {
                        pageImage = Image(decorative: cgImage, scale: 1.0)
                    }
                }
                continuation.resume()
            }
        }
    }
}
