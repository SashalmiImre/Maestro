//
//  PDFPageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 14/12/2024.
//

import SwiftUI
import PDFKit

struct LazyLoadingView: View {
    @State private var isLoading: Bool = true
    @State private var pageImage: Image? = nil
    @State private var cache = NSCache<NSString, NSImage>()

    var pdfPage: PDFPage
    var displayBox: PDFDisplayBox = .trimBox
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
