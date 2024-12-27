//
//  PagePairView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI

/// Egy oldalpár megjelenítése
struct PagePairView: View {
    let leftNumber: Int
    let rightNumber: Int
    let leftPage: Layout.Page?
    let rightPage: Layout.Page?
    let scale: CGFloat
    let defaultSize: CGSize
    let draggedArticle: String?
    let isEditMode: Bool
    let onDragStarted: (Layout.Page) -> Void
    let maxPageNumber: Int
    let handleDrop: (Int) -> Void
    let onHover: (Bool, Int) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 0) {
                // Bal oldal
                if leftNumber > 0 {
                    PageView(
                        page: leftPage,
                        scale: scale,
                        defaultSize: defaultSize,
                        isDragging: leftPage.map { draggedArticle == $0.articleName } ?? false,
                        onDragStarted: onDragStarted,
                        pageNumber: leftNumber,
                        isEditMode: isEditMode,
                        maxPageNumber: maxPageNumber,
                        onDrop: handleDrop,
                        onHover: onHover
                    )
                } else {
                    PageBlankView(scale: scale, defaultSize: defaultSize)
                }
                
                // Jobb oldal
                if rightNumber <= maxPageNumber {
                    PageView(
                        page: rightPage,
                        scale: scale,
                        defaultSize: defaultSize,
                        isDragging: rightPage.map { draggedArticle == $0.articleName } ?? false,
                        onDragStarted: onDragStarted,
                        pageNumber: rightNumber,
                        isEditMode: isEditMode,
                        maxPageNumber: maxPageNumber,
                        onDrop: handleDrop,
                        onHover: onHover
                    )
                } else {
                    PageBlankView(scale: scale, defaultSize: defaultSize)
                }
            }
            .frame(width: defaultSize.width * scale * 2, height: defaultSize.height * scale)
            
            // Oldalszámok külön sorban
            HStack(spacing: 0) {
                let pageNumberFontSize = 24 * scale
                Text("\(leftNumber)")
                    .font(.system(size: pageNumberFontSize))
                    .foregroundColor(.gray)
                    .frame(width: defaultSize.width * scale, alignment: .leading)
                    .padding(.leading, 4)
                    .opacity(leftNumber > 0 ? 1 : 0)
                
                Text("\(rightNumber <= maxPageNumber ? String(rightNumber) : "")")
                    .font(.system(size: pageNumberFontSize))
                    .foregroundColor(.gray)
                    .frame(width: defaultSize.width * scale, alignment: .trailing)
                    .padding(.trailing, 4)
                    .opacity(rightNumber > 0 ? 1 : 0)
            }
        }
    }
}
