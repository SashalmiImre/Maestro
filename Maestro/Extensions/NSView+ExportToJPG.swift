//
//  NSView+ExportToJPG.swift
//  Maestro
//
//  Created by Sashalmi Imre on 28/12/2024.
//

import AppKit
import CoreGraphics

@available(macOS 10.13, *)
extension NSView {
    @discardableResult
    func exportToJPG(fileName: String, scale: CGFloat = 1.0) -> Bool {
        // Ellenőrizzük, hogy a view rendelkezik-e layer-rel
        self.viewWillDraw()
        
        // Make sure we're on the main thread
        guard Thread.isMainThread else {
            print("Az exportálásnak a fő szálon kell történnie")
            return false
        }
        
        // Ellenőrizzük, hogy a view rendelkezik-e layer-rel
        if layer == nil {
            self.wantsLayer = true
            self.layer = CALayer()
        }
        
        // Ellenőrizzük, hogy a view mérete érvényes-e
        self.layoutSubtreeIfNeeded()
        self.displayIfNeeded()
        
        // Ellenőrizzük, hogy a view mérete érvényes-e
        let viewFrame = self.frame
        guard viewFrame.size.width > 0, viewFrame.size.height > 0 else {
            print("A view mérete érvénytelen - Szélesség: \(viewFrame.width), Magasság: \(viewFrame.height)")
            return false
        }
        
        guard let bitmap = self.bitmapImage(scale: scale) else { return false }
        guard let imageRep = bitmap.representations[0] as? NSBitmapImageRep else { return false }
        guard let imageData = imageRep.representation(using: .jpeg, properties: [:]) else { return false }
        
        let fileManager = FileManager.default
        let desktopPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = desktopPath.appendingPathComponent(fileName).appendingPathExtension("jpg")
        
        do {
            try imageData.write(to: fileURL)
            print("A kép sikeresen elmentve: \(fileURL.path)")
            return true
        } catch {
            print("Hiba történt a fájl mentése közben: \(error.localizedDescription)")
            return false
        }
    }
    
    private func bitmapImage(scale: CGFloat = 1.0) -> NSImage? {
        guard let bitmapRep = bitmapImageRepForCachingDisplay(in: bounds) else { return nil }
        bitmapRep.size = NSSize(width: bounds.size.width * scale, height: bounds.size.height * scale)
        cacheDisplay(in: bounds, to: bitmapRep)
        
        let image = NSImage(size: bitmapRep.size)
        image.addRepresentation(bitmapRep)
        
        return image
    }
}
