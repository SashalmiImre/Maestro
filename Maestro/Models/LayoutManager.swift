import Foundation
import PDFKit

public class LayoutManager {
    public static func createLayouts(from articles: [Article]) -> [LayoutVersion] {
        // Megkeressük a legnagyobb oldalszámot
        let maxPage = articles.reduce(0) { max($0, $1.endPage) }
        
        // Oldalpárok létrehozása
        var pagePairs: [PagePair] = []
        
        for pageNum in stride(from: 1, through: maxPage, by: 2) {
            let leftPage = pageNum
            let rightPage = pageNum + 1
            
            // Megkeressük a megfelelő cikkeket az oldalakhoz
            let leftDoc = articles.first { $0.pages[leftPage] != nil }?.pages[leftPage]
            let rightDoc = articles.first { $0.pages[rightPage] != nil }?.pages[rightPage]
            
            pagePairs.append(PagePair(
                leftDocument: leftDoc,
                rightDocument: rightDoc,
                leftPage: leftPage,
                rightPage: rightPage
            ))
        }
        
        // Oldalpárok csoportosítása sorokba (5 pár soronként)
        var versions: [LayoutVersion] = []
        var currentVersion = pagePairs
        versions.append(LayoutVersion(label: "1", pagePairs: currentVersion))
        
        return versions
    }
} 
