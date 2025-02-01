import PDFKit
import SwiftUI

extension PDFPage {
    static func createErrorPage(message: String) -> PDFPage {
        // A4 méret pontokban (72 DPI mellett): 595.2 x 841.8
        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)
        
        // PDF Data létrehozása
        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageRect.size)
        
        if let context = CGContext(consumer: CGDataConsumer(data: data)!,
                                   mediaBox: &mediaBox,
                                   nil) {
            // Normál rajzolás, ha sikerült létrehozni a kontextust
            context.setFillColor(NSColor.white.cgColor)
            context.fill(pageRect)
            
            // SFSymbol rajzolása
            if let symbolImage = NSImage(systemSymbolName: "exclamationmark.triangle.fill", accessibilityDescription: nil) {
                let symbolSize: CGFloat = 100
                let symbolRect = CGRect(x: (pageRect.width - symbolSize) / 2,
                                        y: (pageRect.height - symbolSize) / 2 - 50,
                                        width: symbolSize,
                                        height: symbolSize)
                
                context.saveGState()
                context.translateBy(x: 0, y: pageRect.height)
                context.scaleBy(x: 1.0, y: -1.0)
                
                if let cgImage = symbolImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    context.draw(cgImage, in: symbolRect)
                }
                context.restoreGState()
            }
            
            // Hibaüzenet szöveg rajzolása
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 18),
                .foregroundColor: NSColor.black,
                .paragraphStyle: paragraphStyle
            ]
            
            let textRect = CGRect(x: 50, y: pageRect.height / 2 + 50,
                                  width: pageRect.width - 100, height: 100)
            
            context.saveGState()
            context.translateBy(x: 0, y: pageRect.height)
            context.scaleBy(x: 1.0, y: -1.0)
            
            (message as NSString).draw(in: textRect, withAttributes: attributes)
            context.restoreGState()
            
            context.flush()
        } else {
            // Fallback: Egyszerű PDF létrehozása szöveggel, ha a kontextus létrehozása sikertelen
            let fallbackPDF = """
                %PDF-1.7
                1 0 obj
                <<
                  /Type /Catalog
                  /Pages 2 0 R
                >>
                endobj
                2 0 obj
                <<
                  /Type /Pages
                  /MediaBox [ 0 0 595.2 841.8 ]
                  /Count 1
                  /Kids [ 3 0 R ]
                >>
                endobj
                3 0 obj
                <<
                  /Type /Page
                  /Parent 2 0 R
                  /Resources <<
                    /Font <<
                      /F1 4 0 R
                    >>
                  >>
                  /Contents 5 0 R
                >>
                endobj
                4 0 obj
                <<
                  /Type /Font
                  /Subtype /Type1
                  /BaseFont /Helvetica
                >>
                endobj
                5 0 obj
                << /Length 44 >>
                stream
                BT
                /F1 18 Tf
                100 500 Td
                (\(message)) Tj
                ET
                endstream
                endobj
                xref
                0 6
                0000000000 65535 f
                0000000010 00000 n
                0000000069 00000 n
                0000000170 00000 n
                0000000305 00000 n
                0000000386 00000 n
                trailer
                <<
                  /Size 6
                  /Root 1 0 R
                >>
                startxref
                484
                %%EOF
                """
            data.append(fallbackPDF.data(using: .ascii)!)
        }
        
        // PDF oldal létrehozása
        if let pdfDocument = PDFDocument(data: data as Data) {
            return pdfDocument.page(at: 0)!
        } else {
            // Végső fallback: Üres oldal létrehozása
            return PDFPage()
        }
    }
}
