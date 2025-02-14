import Foundation
import PDFKit

actor Layout: Hashable {
    private static      let a4Size: NSRect = NSRect(x: 0, y: 0, width: 595, height: 842)
    
    unowned             let publication: Publication
    nonisolated(unsafe) var articles: Array<Article>
    nonisolated(unsafe) private(set) var maxPageSizes: Dictionary<PDFDisplayBox, NSRect> = [.artBox   : .zero,
                                                                                            .bleedBox : .zero,
                                                                                            .trimBox  : .zero,
                                                                                            .mediaBox : .zero,
                                                                                            .cropBox  : .zero]
    
    init(publication: Publication, articles: Array<Article> = .init()) {
        self.publication = publication
        self.articles    = articles
    }
    
//    var coverage 
    
    var pages: [Page] {
        print("pages")
        return articles
            .flatMap { $0.pages }
            .sorted { $0.pageNumber < $1.pageNumber }
    }
    
    var maxPageNumber: Int {
        articles
            .map { $0.coverage.upperBound }
            .max() ?? 0
    }

    var printingPageCount: Int {
        let coverPageCount = 4
        let pageCount = maxPageNumber - coverPageCount
        let remainder = pageCount % 8
        let innerPages = remainder == 0 ? pageCount : pageCount + (8 - remainder)
        return innerPages + coverPageCount
    }
    
    @discardableResult
    func add(_ article: Article) -> Bool {
        let hasNoConflict = !articles.contains { $0.overlaps(with: article) }
        if hasNoConflict {
            articles.append(article)
            return true
        }
        return false
    }
    
    
    func pagePairs(maxPageCount: Int) -> Array<PagePair> {
        let adjustedMaxCount = maxPageCount + (maxPageCount.isMultiple(of: 2) ? 0 : 1)
        let articleDict = Dictionary(uniqueKeysWithValues: articles.flatMap { article in
            article.coverage.map { pageNumber in
                
                // TODO: Ez csak tákolás, ehelyett majd jobbat kell csinálni
                if let pageSize = article.pages.first!.pdfPage?.bounds(for: .trimBox),
                   let storedSize = maxPageSizes[.trimBox] {
                    let width  = max(storedSize.width,  pageSize.width)
                    let height = max(storedSize.height, pageSize.height)
                    maxPageSizes[.trimBox] = NSRect(x: 0, y: 0, width: width, height: height)
                }
                return (pageNumber, article)
            }
        })
        
        return (0...adjustedMaxCount)
            .filter { $0.isMultiple(of: 2) }
            .map { startIndex -> PagePair in
                let leftArticle = articleDict[startIndex]
                let rightArticle = articleDict[startIndex + 1]
                
                return PagePair(coverage: startIndex...startIndex + 1,
                                leftArticle: leftArticle,
                                rightArticle: rightArticle)
            }
    }
    
//    subscript(pageNumber: Int) -> Page? {
//        guard pageNumber
//        pagePairs(maxPageCount: manager.maxPageNumber)
//            .first { $0.coverage.contains(pageNumber)
//    }
    
    // MARK: - Protocol Conformance
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(articles)
    }
    
    static func == (lhs: Layout, rhs: Layout) -> Bool {
        // Two layouts are equal if they have the same articles in the same order
        lhs.articles == rhs.articles
    }
}
