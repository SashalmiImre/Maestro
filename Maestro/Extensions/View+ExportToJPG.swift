//
//  View+ExportToJPG.swift
//  Maestro
//
//  Created by Sashalmi Imre on 28/12/2024.
//

import SwiftUI
import AppKit

@available(macOS 10.13, *)
extension View {
    func exportToJPG<T: ObservableObject>(fileName: String, scale: CGFloat = 2.0, withEnvironment object: T) {
        let hostingView = NSHostingView(rootView: self.environmentObject(object))
        
        // First set the frame size to the fitting size
        hostingView.frame.size = hostingView.fittingSize
        
        // Force initial layout
        hostingView.layout()
        
        // Add the view to a window temporarily to ensure proper rendering
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.frame.size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false)
        window.contentView = hostingView
        
        // Force layout again after adding to window
        hostingView.layoutSubtreeIfNeeded()
        
        // Wait for the next run loop to ensure rendering is complete
        DispatchQueue.main.async {
            // Use the existing fileName based function
            let _ = hostingView.exportToJPG(fileName: fileName, scale: scale)
            
            // Clean up
            window.contentView = nil
        }
    }
}
