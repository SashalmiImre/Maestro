import Foundation
import PDFKit

public struct LayoutVersion: Identifiable {
    public let id = UUID()
    public let label: String
    public let pagePairs: [PagePair]
    
    public init(label: String, pagePairs: [PagePair]) {
        self.label = label
        self.pagePairs = pagePairs
    }
} 
