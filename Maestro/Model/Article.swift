import Foundation
import PDFKit

actor Article: Equatable, Hashable, @unchecked Sendable {
    unowned let publication: Publication
    let name: String
    let coverage: ClosedRange<Int>
    let inddFile: URL
    let pdfFile: URL
    nonisolated(unsafe) var pages: [Page] = .init()

    // MARK: - Properties
    
    /// Indicates whether the PDF file is in the final PDF folder of the publication
    nonisolated var hasFinalPDF: Bool {
        pdfFile.isSubfolder(of: publication.pdfFolder)
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

        // Find and validate matching PDF
        guard let pdfURL = await Article.findMatchingPDF(for: inddFileName, publication: publication, in: availablePDFs),
              let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }

        // Store the PDF source
        self.pdfFile = pdfURL

        // Oldalak feldolgozása és tárolása
        switch pdfDocument.collectingPages(coverage: coverage) {
        case .failure(let error):
            // TODO: Kezelni kell
            print(error.localizedDescription)
            return nil
        case .success(let pdfPages):
            let newPages = pdfPages.map { (pageNumber: Int, pdfPage: PDFPage) in
                let pdfData = pdfPage.dataRepresentation
                return Page(article: self, pageNumber: pageNumber, pdfData: pdfData)
            }
            self.pages = newPages
        }
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
            guard inddFileName.calculateSimilarity(with: pdfFileName) > 0.9,
                  let pdfParsed = FileNameParser.parse(fileName: pdfFileName),
                  inddParsed.magazine.name == pdfParsed.magazine.name,
                  inddParsed.startPage     == pdfParsed.startPage,
                  inddParsed.endPage       == pdfParsed.endPage else {
                return nil
            }
            
            // Remove the page numbers from both filenames for better comparison
            let inddNameWithoutPages = inddParsed.articleName ?? inddFileName
            let pdfNameWithoutPages  = pdfParsed.articleName  ?? pdfFileName
            
            guard pdfURL.isSubfolder(of: publication.pdfFolder) else {
                return (pdfURL, Double.greatestFiniteMagnitude)
            }
            
            // Calculate similarity between names without page numbers
            let similarity = inddNameWithoutPages.calculateSimilarity(with: pdfNameWithoutPages)
            return (pdfURL, similarity)
        }
        
        // Return the PDF with the highest similarity score
        // No minimum threshold to ensure we always get a match if pages align
        return matchingPageRangePDFs
            .max(by: { $0.similarity < $1.similarity })?
            .url
    }
    
    // MARK: - Page Access
    
    subscript(pageNumber: Int) -> Page? {
        pages.first { page in
            page.pageNumber == pageNumber
        }
    }

    /// Ellenőrzi, hogy van-e átfedés két cikk között az oldalszámozásban
    /// - Parameter other: A másik cikk, amivel az átfedést vizsgáljuk
    /// - Returns: True, ha van átfedés a két cikk oldalszámai között
    nonisolated(unsafe) func overlaps(with other: Article) -> Bool {
        return self.coverage.overlaps(other.coverage)
    }
}
