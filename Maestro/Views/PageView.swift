//
//  PageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI

struct PageView: View {
        @EnvironmentObject var manager: PublicationManager
        
        let page: Layout.Page?
        let scale: CGFloat
        let defaultSize: CGSize
        let isDragging: Bool
        let onDragStarted: (Layout.Page) -> Void
        let pageNumber: Int
        let isEditMode: Bool
        let maxPageNumber: Int
        let onDrop: (Int) -> Void
        let onHover: (Bool, Int) -> Void
        
        private var isPDFFromWorkflow: Bool {
            guard let page = page,
                  let pdfFolder = manager.publication?.pdfFolder else { return true }
            return page.pdfSource.isSubfolder(of: pdfFolder)
        }
        
    fileprivate func emptyNumberedPage() -> some View {
        return Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(
                width: defaultSize.width * scale,
                height: defaultSize.height * scale
            )
            .overlay(
                Text("\(pageNumber)")
                    .font(.system(size: 120 * scale))
                    .foregroundColor(.gray.opacity(0.3))
            )
            .dropDestination(for: String.self) { items, _ in
                if isEditMode {
                    onDrop(pageNumber)
                    return true
                }
                return false
            } isTargeted: { isTargeted in
                onHover(isTargeted, pageNumber)
            }
    }
    
    var body: some View {
            Group {
                if let page = page {
                    PDFPageRendererView(
                        pdfPage: page.pdfDocument.page(at: 0)!,
                        displayBox: .trimBox,
                        scale: scale
                    )
                    .frame(
                        width: defaultSize.width * scale,
                        height: defaultSize.height * scale
                    )
                    .background(Color.white)
                    .opacity(isDragging ? 0.7 : 1.0)
                    .onTapGesture {
                        if isEditMode {
                            onDragStarted(page)
                        }
                    }
                    .overlay(isDragging && isEditMode ? Color.blue.opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(isPDFFromWorkflow ? Color.clear : Color.red, lineWidth: 2)
                    )
                    .dropDestination(for: String.self) { items, _ in
                        if isEditMode {
                            onDrop(pageNumber)
                            return true
                        }
                        return false
                    } isTargeted: { isTargeted in
                        onHover(isTargeted, pageNumber)
                    }
                } else if pageNumber > 0 && pageNumber <= maxPageNumber {
                    emptyNumberedPage()
                }
            }
            .frame(
                width: defaultSize.width * scale,
                height: defaultSize.height * scale,
                alignment: .center
            )
            .clipped()
        }
    }
