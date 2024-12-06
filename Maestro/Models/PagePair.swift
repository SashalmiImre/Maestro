import Foundation
import PDFKit

public struct PagePair: Identifiable {
    public let id = UUID()
    public let leftPage: Int
    public let rightPage: Int
    public let leftDocument: PDFDocumentInfo?
    public let rightDocument: PDFDocumentInfo?
    
    public init(leftDocument: PDFDocumentInfo?,
                rightDocument: PDFDocumentInfo?,
                leftPage: Int,
                rightPage: Int) {
        self.leftPage = leftPage
        self.rightPage = rightPage
        self.leftDocument = leftDocument
        self.rightDocument = rightDocument
    }
} 
