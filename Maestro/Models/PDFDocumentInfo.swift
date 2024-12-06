public struct PDFDocumentInfo: Identifiable, Hashable {
    public let id = UUID()
    public let url: URL
    public let document: PDFKit.PDFDocument
    public let name: String
    public let pageCount: Int
    public let type: Magazine
    public let startPage: Int
    public let endPage: Int?
    public let articleName: String?
    
    public init?(url: URL) {
        guard let document = PDFKit.PDFDocument(url: url),
              let parsedName = FileNameParser.parse(fileName: url.deletingPathExtension().lastPathComponent) else { 
            return nil 
        }
        
        self.url = url
        self.document = document
        self.name = url.deletingPathExtension().lastPathComponent
        self.pageCount = document.pageCount
        self.type = parsedName.magazine
        self.startPage = parsedName.startPage
        self.endPage = parsedName.endPage
        self.articleName = parsedName.articleName
    }
} 