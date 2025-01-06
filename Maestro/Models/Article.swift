import Foundation
import PDFKit

class Article: Equatable, Hashable {
    let publication: Publication
    let name: String
    let coverage: ClosedRange<Int>
    let inddFile: URL
    let pdfFile: URL
    var pages: [Page] = .init()

    // MARK: - Properties
    
    /// Indicates whether the PDF file is in the final PDF folder of the publication
    var hasFinalPDF: Bool {
        pdfFile.isSubfolder(of: publication.pdfFolder)
    }

    // MARK: - Protocol Conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(inddFile)
        hasher.combine(pdfFile)
    }

    static func == (lhs: Article, rhs: Article) -> Bool {
        return lhs.inddFile == rhs.inddFile && lhs.pdfFile == rhs.pdfFile
    }

    
    // MARK: - Private Helpers
    
    private static func findMatchingPDF(for inddFileName: String, in availablePDFs: [URL]) -> URL? {
        var bestMatch: (url: URL, similarity: Double)? = nil

        for pdfURL in availablePDFs {
            let pdfFileName = pdfURL.deletingPathExtension().lastPathComponent
            let similarity  = inddFileName.calculateSimilarity(with: pdfFileName)

            if similarity >= 0.8 && (bestMatch == nil || similarity > bestMatch!.similarity) {
                bestMatch = (pdfURL, similarity)
            }
        }

        return bestMatch?.url
    }

    
    // MARK: - Initialization
    
    init?(publication: Publication, inddFile: URL, availablePDFs: [URL]) {
        // Fájlnév feldolgozása
        let inddFileName = inddFile.deletingPathExtension().lastPathComponent
        guard let parsedName = FileNameParser.parse(fileName: inddFileName) else {
            return nil
        }

        self.publication = publication
        self.name     = parsedName.articleName ?? inddFile.deletingPathExtension().lastPathComponent
        self.inddFile = inddFile
        self.coverage = parsedName.startPage...(parsedName.endPage ?? parsedName.startPage)

        // Find and validate matching PDF
        guard let pdfURL = Self.findMatchingPDF(for: inddFileName, in: availablePDFs),
              let pdfDocument = PDFDocument(url: pdfURL) else {
            return nil
        }

        // Store the PDF source
        self.pdfFile = pdfURL

        // Oldalak feldolgozása és tárolása
        switch pdfDocument.collectingPages(coverage: coverage) {
        case .failure(let error):
            return nil
        case .success(let pdfPages):
            let newPages = pdfPages.map { (pageNumber: Int, pdfPage: PDFDocument) in
                Page(article: self, pageNumber: pageNumber, pdfPage: pdfPage)
            }
            self.pages = newPages
        }
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
    func overlaps(with other: Article) -> Bool {
        return self.coverage.overlaps(other.coverage)
    }
}
