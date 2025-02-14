import Foundation
import PDFKit

actor Article: Equatable, Hashable {
    unowned     let publication: Publication
                let name: String
                let coverage: ClosedRange<Int>
                let inddFile: URL
                let pdfFile: URL
    
    nonisolated var hasFinalPDF: Bool {
        pdfFile.isSubfolder(of: publication.pdfFolder)
    }

    
    // MARK: - Initialization
    
    init?(publication: Publication, inddFile: URL, availablePDFs: [URL]) async {
        // Fájlnév feldolgozása
        let inddFileName = inddFile.deletingPathExtension().lastPathComponent
        guard let parsedName = FileNameParser.parse(fileName: inddFileName) else {
            return nil
        }

        self.publication = publication
        self.name        = parsedName.articleName ?? inddFileName
        self.inddFile    = inddFile
        self.coverage    = parsedName.startPage...(parsedName.endPage ?? parsedName.startPage)

        // Megkeresi a megfelelő PDF-fájlt
        guard let pdfURL = await Article.findMatchingPDF(for: inddFileName, publication: publication, in: availablePDFs) else {
            return nil
        }
        self.pdfFile = pdfURL
    }

    
    // MARK: - Private Helpers
    
    private static func findMatchingPDF(for inddFileName: String, publication: Publication, in availablePDFs: [URL]) async -> URL? {
        // Parse the INDD filename to get the page range
        guard let inddParsed = FileNameParser.parse(fileName: inddFileName) else {
            return nil
        }
        
        // First, find all PDFs that match the page range
        let matchingPageRangePDFs = availablePDFs.compactMap { pdfURL -> (url: URL, similarity: Double)? in
            let pdfFileName = pdfURL.deletingPathExtension().lastPathComponent
            guard inddFileName.calculateSimilarity(with: pdfFileName) > 0.8,
                  let pdfParsed = FileNameParser.parse(fileName: pdfFileName),
                  inddParsed.magazine.name == pdfParsed.magazine.name,
                  inddParsed.startPage     == pdfParsed.startPage,
                  inddParsed.endPage       == pdfParsed.endPage else {
                return nil
            }
            
            let inddNameWithoutPages = inddParsed.articleName ?? inddFileName
            let pdfNameWithoutPages  = pdfParsed.articleName  ?? pdfFileName
            
            if pdfURL.isSubfolder(of: publication.pdfFolder) {
                return (pdfURL, Double.greatestFiniteMagnitude)
            }
            
            let similarity = inddNameWithoutPages.calculateSimilarity(with: pdfNameWithoutPages)
            return (pdfURL, similarity)
        }
        
        return matchingPageRangePDFs
            .max(by: { $0.similarity < $1.similarity })?
            .url
    }
    
    
    
    // MARK: - Protocol Conformance
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(inddFile)
        hasher.combine(pdfFile)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.inddFile == rhs.inddFile
               && lhs.pdfFile == rhs.pdfFile
    }

    
    
    // MARK: - Page Access
    
    nonisolated lazy var pages: Array<Page> = {
        guard let pdfDocument = PDFDocument(url: pdfFile) else {
            return .init()
        }
        
        var pages: Array<Page> = .init()
        switch pdfDocument.collectingPages(coverage: coverage, displayBox: .trimBox) {
        case .failure(let error):
            // TODO: Kezelni kell
            print("Page generálási hiba: \(error.localizedDescription)")
            return .init()
        case .success(let pdfPages):
            pages = pdfPages.map { (pageNumber: Int, pdfPage: PDFPage) in
                let pdfData = pdfPage.dataRepresentation
                return Page(pageNumber: pageNumber, article: self, pdfData: pdfData)
            }
        }
        return pages
    }()
    
    
    nonisolated subscript(pageNumber: Int) -> Page? {
        pages.first { page in
            page.pageNumber == pageNumber
        }
    }

    
    
    // MARK: - Overlap
    
    nonisolated func overlaps(with other: Article) -> Bool {
        return self.coverage.overlaps(other.coverage)
    }
}
