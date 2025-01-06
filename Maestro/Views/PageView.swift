//
//  PageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI

struct PageView: View {
    @EnvironmentObject var manager: PublicationManager
    
    let page: Page
    
    var body: some View {
        if let pdfPage = page.pdfPage?.page(at: 0) {
            PDFPageRendererView(
                pdfPage: pdfPage,
                displayBox: .trimBox
            )
            .background(Color.white)
            .overlay(manager.isEditMode ? Color.blue.opacity(0.3) : Color.clear)
            .overlay(
                Rectangle()
                    .stroke(page.article!.hasFinalPDF ? Color.clear : Color.red, lineWidth: 2)
            )
        } else {
            emptyNumberedPage()
        }
    }
    
    fileprivate func emptyNumberedPage() -> some View {
        return Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(
                width: manager.selectedLayout!.maxPageSize(for: .trimBox).width * manager.zoomLevel,
                height: manager.selectedLayout!.maxPageSize(for: .trimBox).height * manager.zoomLevel
            )
            .overlay(
                Text("\(page.pageNumber)")
                    .font(.system(size: 240 * manager.zoomLevel))
                    .foregroundColor(.gray.opacity(0.20))
            )
    }
}
