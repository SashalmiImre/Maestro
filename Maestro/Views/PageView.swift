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
        Group {
            if let pdfPage = page.pdfPage {
                PageRendererView(pdfPage: pdfPage)
                    .background(Color.white)
                    .overlay(manager.isEditMode ? Color.blue.opacity(0.3) : Color.clear)
            } else {
                EmptyNumberedPageView(page: page, manager: manager)
            }
        }
    }
}

struct EmptyNumberedPageView: View {
    let page: Page
    @ObservedObject var manager: PublicationManager
    
    @State private var size: CGSize = .zero
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.1))
            .frame(
                width: size.width * manager.zoomLevel,
                height: size.height * manager.zoomLevel
            )
            .overlay(
                Text("\(page.pageNumber)")
                    .font(.system(size: 240 * manager.zoomLevel))
                    .foregroundColor(.gray.opacity(0.10))
            )
            .task {
                if let layout = manager.selectedLayout {
                    let rect = await layout.maxPageSize(for: .trimBox)
                    size = rect.size
                }
            }
    }
}
