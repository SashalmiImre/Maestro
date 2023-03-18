//
//  LayoutEditorView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 08..
//

import SwiftUI
import GridStack
import RealmSwift

struct LayoutEditorView: View {
    @ObservedRealmObject var publication: Publication = Publication.publication1
    
    var body: some View {
        GridStack(
            minCellWidth: 200,
            spacing: 0,
            numItems: publication.endPageNumber / 2 + 1,
            alignment: .leading) { (index, cellWidth) in
                pagePair(index: index)
            }
        
    }
    
    @ViewBuilder
    func pagePair(index: Int) -> some View {
        let lowerPageIndex = index * 2
        let upperPageIndex = lowerPageIndex + 1
        HStack(spacing: 0) {
            PageView(publication: Publication.publication1,
                     pageNumber: lowerPageIndex,
                     isDummy: lowerPageIndex < publication.startPageNumber)
            PageView(publication: Publication.publication1,
                     pageNumber: upperPageIndex,
                     isDummy: upperPageIndex > publication.endPageNumber)
        }
    }
}


// MARK: - Previews

struct LayoutEditor_Previews: PreviewProvider {
    static var previews: some View {
        LayoutEditorView(publication: Publication.publication1)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationDetails Mac")
        
        LayoutEditorView(publication: Publication.publication1)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationDetails iOS")
    }
}
