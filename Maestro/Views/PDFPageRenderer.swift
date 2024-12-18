////
////  PDFPageRenderer.swift
////  Maestro
////
////  Created by Sashalmi Imre on 14/12/2024.
////
//
//import SwiftUI
//import PDFKit
//
//// PDF renderelés cache
//final class PDFPageRenderer {
//    static let shared = PDFPageRenderer()
//    private var cache = NSCache<NSString, NSImage>()
//    
//    private init() {
//        cache.countLimit = 500
//    }
//    
//    deinit {
//        clearCache()
//    }
//    
//    func image(for page: PDFPage, scale: CGFloat, displayBox: PDFDisplayBox) -> NSImage? {
//        let key = "\(page.hash)_\(scale)_\(displayBox.rawValue)" as NSString
//        
//        if let cachedImage = cache.object(forKey: key) {
//            return cachedImage
//        }
//        
//        let bounds = page.bounds(for: displayBox)
//        let size = CGSize(width: bounds.width * scale, height: bounds.height * scale)
//        
//        let renderedImage = NSImage(size: size)
//        renderedImage.lockFocus()
//        let context = NSGraphicsContext.current!.cgContext
//        context.scaleBy(x: scale, y: scale)
//        page.draw(with: displayBox, to: context)
//        renderedImage.unlockFocus()
//        
//        cache.setObject(renderedImage, forKey: key)
//        return renderedImage
//    }
//    
//    func clearCache() {
//        cache.removeAllObjects()
//    }
//}
