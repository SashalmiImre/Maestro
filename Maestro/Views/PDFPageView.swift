//
//  PDFPageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 14/12/2024.
//

import SwiftUI
import PDFKit

//struct PDFPageView: View {
//    var pdfPage: PDFPage
//    var displayBox: PDFDisplayBox = .cropBox
//    var scale: CGFloat
//    
//    // Cache-eljük a méreteket
//    private var pageSize: CGSize {
//        let bounds = pdfPage.bounds(for: displayBox)
//        return CGSize(width: bounds.width * scale, height: bounds.height * scale)
//    }
//    
//    var body: some View {
//        PDFPageContentView(
//            pdfPage: pdfPage,
//            displayBox: displayBox,
//            scale: scale,
//            size: pageSize
//        )
//        .frame(width: pageSize.width, height: pageSize.height)
//    }
//}
//
//// Külön view a rendereléshez
//private struct PDFPageContentView: NSViewRepresentable {
//    let pdfPage: PDFPage
//    let displayBox: PDFDisplayBox
//    let scale: CGFloat
//    let size: CGSize
//    
//    func makeNSView(context: Context) -> NSImageView {
//        let imageView = NSImageView()
//        imageView.imageScaling = .scaleNone
//        return imageView
//    }
//    
//    func updateNSView(_ nsView: NSImageView, context: Context) {
//        if let image = PDFPageRenderer.shared.image(for: pdfPage, scale: scale, displayBox: displayBox) {
//            nsView.image = image
//        }
//    }
//}




struct LazyLoadingView: View {
    @State private var isLoading: Bool = true
    @State private var pageImage: Image? = nil
    @State private var cache = NSCache<NSString, NSImage>()

    var pdfPage: PDFPage
    var displayBox: PDFDisplayBox = .cropBox
    var scale: CGFloat
    
    // Cache-eljük a méreteket
    private var pageSize: CGSize {
        let bounds = pdfPage.bounds(for: displayBox)
        return CGSize(width: bounds.width * scale, height: bounds.height * scale)
    }
    
    var body: some View {
        ZStack {
            if isLoading {
                VStack {
                    let key = "\(pdfPage.hash)_\(scale)_\(displayBox.rawValue)" as NSString
                    
                    if let cachedImage = cache.object(forKey: key) {
                        Image(nsImage: cachedImage)
                    } else {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                }
            } else {
                pageImage
            }
        }
        .frame(width: pageSize.width, height: pageSize.height)
        .onAppear {
            renderImage()
        }
    }
    
    private func renderImage() {
        DispatchQueue.global(qos: .userInitiated).async {

            let bounds = pdfPage.bounds(for: displayBox)
            let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
            
            let renderedImage = NSImage(size: size)
            renderedImage.lockFocus()
            let context = NSGraphicsContext.current!.cgContext
            context.scaleBy(x: scale, y: scale)
            pdfPage.draw(with: displayBox, to: context)
            renderedImage.unlockFocus()
            
            let key = "\(pdfPage.hash)_\(scale)_\(displayBox.rawValue)" as NSString
            cache.setObject(renderedImage, forKey: key)
            DispatchQueue.main.async {
                pageImage = Image(nsImage: renderedImage)
                isLoading = false
            }
        }
    }
}
