import Foundation

enum Magazine: String {
    case story = "S"
    case best = "BEST"
}

struct ParsedFileName {
    let magazine: Magazine
    let startPage: Int
    let endPage: Int?
    let articleName: String?
}

class FileNameParser {
    private static let pattern = #"^(?:([sS])|(?i:BEST))\s+(\d{1,3})(?:\s+(\d{1,3}))?\s*(.+)?$"#
    
    static func parse(fileName: String) -> ParsedFileName? {
        guard let match = fileName.matches(pattern: pattern).first else { return nil }
        
        let nsString = fileName as NSString
        
        // Magazine típus meghatározása
        let magazine: Magazine
        if match.range(at: 1).location != NSNotFound {
            magazine = .story
        } else {
            magazine = .best
        }
        
        // Kezdő oldalszám
        let startPage = Int(nsString.substring(with: match.range(at: 2))) ?? 0
        
        // Végső oldalszám (ha van)
        let endPage = match.range(at: 3).location != NSNotFound ?
            Int(nsString.substring(with: match.range(at: 3))) : nil
        
        // Cikk neve (ha van)
        let articleName = match.range(at: 4).location != NSNotFound ?
            nsString.substring(with: match.range(at: 4)).trimmingCharacters(in: CharacterSet.whitespaces) : nil
        
        return ParsedFileName(
            magazine: magazine,
            startPage: startPage,
            endPage: endPage,
            articleName: articleName
        )
    }
}

private extension String {
    func matches(pattern: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(
            in: self,
            range: NSRange(location: 0, length: self.utf16.count)
        )
    }
} 
