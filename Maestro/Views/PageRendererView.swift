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
    
    private var pageSize: CGSize {
        let bounds = pdfPage.bounds(for: displayBox)
        return CGSize(width:  (bounds.width * manager.zoomLevel).rounded(.down),
                      height: (bounds.height * manager.zoomLevel).rounded(.down))
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
            .onAppear() {
                Task {
                    await renderPDFPageAsync()
                }
            }
            .onChange(of: manager.zoomLevel) { _, newValue in
                Task {
                    await renderPDFPageAsync()
                }
            }
        }
    }
    
    
    nonisolated private func renderPDFPage(page: PDFPage, size: CGSize, zoom: CGFloat) -> CGImage? {
        
        var image: CGImage? = nil
        
        guard let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.saveGState()
        context.interpolationQuality = .high
        context.setAllowsAntialiasing(true)
        context.scaleBy(x: zoom, y: zoom)
        
        page.draw(with: .trimBox, to: context)
        
        context.restoreGState()
        image = context.makeImage()
        context.flush()
        
        return image
    }
    
    // MARK: - Renderers
    
    private func renderPDFPageSync() -> Image {
        guard let cgImage = renderPDFPage(page: pdfPage, size: pageSize, zoom: manager.zoomLevel) else {
            return Image(systemName: "xmark.rectangle.portrait")
        }
        return Image(decorative: cgImage, scale: 1.0)
    }
    

    private func renderPDFPageAsync() async {
        // Create isolated copies of the values
        let isolatedPage = pdfPage
        let isolatedSize = pageSize
        let isolatedZoom = manager.zoomLevel
        
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                if let cgImage = renderPDFPage(page: isolatedPage, size: isolatedSize, zoom: isolatedZoom) {
                    DispatchQueue.main.async {
                        pageImage = Image(decorative: cgImage, scale: 1.0)
                    }
                }
                continuation.resume()
            }
        }
    }
}
