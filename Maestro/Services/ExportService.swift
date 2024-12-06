//
//  ExportService.swift
//  Maestro
//
//  Created by Sashalmi Imre on 05/12/2024.
//

import Foundation
import PDFKit

public enum ExportService {
    public static let rowSpacing: CGFloat = 20
    public static let pairSpacing: CGFloat = 10
    public static let pairsPerRow = 3
    
    public enum ExportError: Error, LocalizedError {
        case renderingFailed
        case savingFailed
        
        public var errorDescription: String? {
            switch self {
            case .renderingFailed:
                return "A PDF oldalak renderelése sikertelen"
            case .savingFailed:
                return "A fájl mentése sikertelen"
            }
        }
    }
    
    public static func exportLayout(_ layout: LayoutVersion, to url: URL) async throws {
        let image = NSImage(size: NSSize(width: 800, height: 600))
        image.lockFocus()
        
        // Fehér háttér
        NSColor.white.set()
        NSBezierPath(rect: NSRect(origin: .zero, size: image.size)).fill()
        
        // Oldalak renderelése
        var y = image.size.height - 100 // Felső margó
        
        for pair in layout.pagePairs {
            if y < 100 { break } // Alsó margó
            
            // Oldalak renderelése
            var y = image.size.height - 100 // Felső margó
            
            for pair in layout.pagePairs {
                if y < 100 { break } // Alsó margó
                
                // Bal oldal renderelése
                if let doc = pair.leftDocument,
                   let page = doc.page(at: pair.leftPage - 1) {
                    let rect = NSRect(x: 50, y: y - 150, width: 200, height: 150)
                    if let context = NSGraphicsContext.current?.cgContext {
                        context.saveGState()
                        context.translateBy(x: rect.origin.x, y: rect.origin.y)
                        context.scaleBy(x: rect.size.width / page.bounds(for: .mediaBox).width,
                                        y: rect.size.height / page.bounds(for: .mediaBox).height)
                        page.draw(with: .mediaBox, to: context)
                        context.restoreGState()
                    }
                }
                
                // Jobb oldal renderelése
                if let doc = pair.rightDocument,
                   let page = doc.page(at: pair.rightPage - 1) {
                    let rect = NSRect(x: 300, y: y - 150, width: 200, height: 150)
                    if let context = NSGraphicsContext.current?.cgContext {
                        context.saveGState()
                        context.translateBy(x: rect.origin.x, y: rect.origin.y)
                        context.scaleBy(x: rect.size.width / page.bounds(for: .mediaBox).width,
                                        y: rect.size.height / page.bounds(for: .mediaBox).height)
                        page.draw(with: .mediaBox, to: context)
                        context.restoreGState()
                    }
                }
                
                y -= 200 // Következő sor
            }
        }
        
        image.unlockFocus()
        
        // Mentés JPEG formátumban
        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
            throw ExportError.renderingFailed
        }
        
        try jpegData.write(to: url)
    }
}
