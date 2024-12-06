import Foundation
import PDFKit

// PDF Document
public struct PDFDocumentInfo: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let document: PDFKit.PDFDocument
    public let name: String
    public let pageCount: Int
    public let type: DocumentType
    public let startPage: Int
    
    public enum DocumentType: String, Hashable {
        case S = "Story"
        case BEST = "BEST"
        case unknown = "UNKNOWN"
        
        public static func from(_ name: String) -> DocumentType {
            if name.hasPrefix("Story") { return .S }
            if name.hasPrefix("BEST") { return .BEST }
            return .unknown
        }
    }
    
    public init?(url: URL) {
        guard let document = PDFKit.PDFDocument(url: url),
              let fileName = url.deletingPathExtension().lastPathComponent
                .split(separator: " ")
                .first
                .map(String.init) else { return nil }
        
        self.url = url
        self.document = document
        self.name = url.deletingPathExtension().lastPathComponent
        self.pageCount = document.pageCount
        self.type = DocumentType.from(fileName)
        
        let components = self.name.split(separator: " ")
        if components.count >= 2,
           let startPage = Int(components[1]) {
            self.startPage = startPage
        } else {
            self.startPage = 1
        }
    }
}
