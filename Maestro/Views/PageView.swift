//
//  PageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI
@preconcurrency import PDFKit

struct PageView: View {
    @EnvironmentObject var manager: PublicationManager
    @EnvironmentObject var context: LayoutViewContext
    
    let page: Page
    let displayBox: PDFDisplayBox = .trimBox
    
    @State private var pageImage: Image? = nil
    @State private var size: CGSize = .zero
    
    private var pageSize: CGSize {
        if let pdfPage = page.pdfPage {
            let bounds = pdfPage.bounds(for: displayBox)
            return CGSize(width: (bounds.width * manager.zoomLevel).rounded(.down),
                          height: (bounds.height * manager.zoomLevel).rounded(.down))
        }
        return size
    }
    
    var body: some View {
        if let pdfPage = page.pdfPage {
            PDFPageView(pdfPage: pdfPage, pageImage: $pageImage, pageSize: pageSize)
                .overlay(manager.isEditMode ? Color.blue.opacity(0.3) : Color.clear)
        } else {
            EmptyPageView(pageNumber: page.pageNumber)
        }
    }
}


// MARK: - PDF Page View Component

private struct PDFPageView: View {
    @EnvironmentObject var manager: PublicationManager
    
    let pdfPage: PDFPage
    @Binding var pageImage: Image?
    let pageSize: CGSize
    
    var body: some View {
        if manager.isExporting {
            renderPDFPageSync()
        } else {
            AsyncPageContentView(pageImage: pageImage, pageSize: pageSize)
                .onAppear {
                    Task {
                        await renderPDFPageAsync()
                    }
                }
                .onChange(of: manager.zoomLevel) { _, _ in
                    Task {
                        await renderPDFPageAsync()
                    }
                }
        }
    }
    
    // MARK: - Rendering Methods
    
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
        
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        
        context.interpolationQuality = .high
        context.setAllowsAntialiasing(true)
        context.scaleBy(x: zoom, y: zoom)
        
        page.draw(with: .trimBox, to: context)
        
        context.restoreGState()
        image = context.makeImage()
        context.flush()
        
        return image
    }
    // Move rendering methods here
    private func renderPDFPageSync() -> Image {
        guard let cgImage = renderPDFPage(page: pdfPage, size: pageSize, zoom: manager.zoomLevel) else {
            return Image(systemName: "xmark.rectangle.portrait")
        }
        return Image(decorative: cgImage, scale: 1.0)
    }
    
    private func renderPDFPageAsync() async {
        return await withCheckedContinuation { continuation in
            Task {
                if let cgImage = renderPDFPage(page: pdfPage, size: pageSize, zoom: manager.zoomLevel) {
                    DispatchQueue.main.async {
                        pageImage = Image(decorative: cgImage, scale: 1.0)
                    }
                }
                continuation.resume()
            }
        }
    }
}


// MARK: - Async Page Content View

private struct AsyncPageContentView: View {
    let pageImage: Image?
    let pageSize: CGSize
    
    var body: some View {
        Group {
            if let image = pageImage {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                ProgressView().progressViewStyle(.circular)
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .animation(.easeInOut(duration: 0.2), value: pageImage != nil)
    }
}


// MARK: - Empty Page View

private struct EmptyPageView: View {
    @EnvironmentObject var manager: PublicationManager
    
    let pageNumber: Int
    
    private var size: CGSize {
        manager.selectedLayout?.maxPageSizes[.trimBox]?.size ?? .zero
    }
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(
                width: size.width * manager.zoomLevel,
                height: size.height * manager.zoomLevel
            )
            .overlay(
                Text("\(pageNumber)")
                    .font(.system(size: 240 * manager.zoomLevel))
                    .foregroundColor(.gray.opacity(0.10))
            )
    }
}
