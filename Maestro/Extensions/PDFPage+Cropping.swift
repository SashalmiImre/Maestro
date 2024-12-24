import PDFKit

extension PDFPage {
    /// Oldal típusok meghatározása
    enum CropSide {
        case left   // Bal oldali fél
        case right  // Jobb oldali fél
        case full   // Teljes oldal
    }
    
    /// Létrehoz egy új PDF dokumentumot az oldal egy meghatározott részéből
    /// - Parameter side: Melyik részét szeretnénk az oldalnak (.left, .right, vagy .full)
    /// - Returns: Új PDF dokumentum a kivágott résszel, vagy nil hiba esetén
    func createPDF(side: CropSide) -> PDFDocument? {
        guard let newPage = self.copy() as? PDFPage else { return nil }
        
        let pageRect = self.bounds(for: .trimBox)
        let halfWidth = pageRect.width / 2
        
        let bounds: CGRect
        switch side {
        case .left:
            bounds = CGRect(x: 0, y: 0, width: halfWidth, height: pageRect.height)
        case .right:
            bounds = CGRect(x: halfWidth, y: 0, width: halfWidth, height: pageRect.height)
        case .full:
            bounds = pageRect
        }
        
        newPage.setBounds(bounds, for: .trimBox)
        
        let newPDF = PDFDocument()
        newPDF.insert(newPage, at: 0)
        
        return newPDF
    }
} 
