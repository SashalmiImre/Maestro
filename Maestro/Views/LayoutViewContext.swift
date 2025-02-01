//
//  LayoutViewContext.swift
//  Maestro
//
//  Created by Sashalmi Imre on 12/01/2025.
//

import Foundation
import SwiftUI

class LayoutViewContext: ObservableObject {
    @Published var scrollViewAvaiableSize: CGSize = .zero
    @Published var scrollViewProxy: ScrollViewProxy?
    
//    private var pageImageCache = NSCache<NSString, NSImage>()
//    
//    func getImage(forKey key: NSString) -> NSImage? {
//        guard let nsImage = pageImageCache.object(forKey: key) else { return nil }
//        return nsImage
//    }
//    
//    func setImage(_ image: NSImage, forKey key: NSString) {
//        pageImageCache.setObject(image, forKey: key as NSString)
//    }
}
