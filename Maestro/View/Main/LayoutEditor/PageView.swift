//
//  PageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 15..
//

import SwiftUI
import RealmSwift

struct PageView: View {
    @ObservedRealmObject var publication: Publication

    var pageNumber: Int
    var isDummy: Bool = false
    var parity: Parity { Parity(pageNumber) }
    var articles: Results<Article> { publication.articles(for: pageNumber) }
    var advertising: Results<Advertising> { publication.advertising(for: pageNumber) }
    
    var body: some View {
        VStack {
            pageNumberView
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: parity == .even ? .bottomLeading : .bottomTrailing)
        }
        .frame(width: 70, height: 100)
    }
    
    @ViewBuilder var pageNumberView: some View {
        Text(isDummy ? "" : String(pageNumber))
            .font(.footnote)
            .padding(.top, 3.0)
    }
}

// MARK: - Parity

extension PageView {
    enum Parity {
        case even, odd
        init(_ number: Int) {
            self = number % 2 == 0 ? .even : .odd
        }
    }
}


// MARK: - Previews

struct PageView_Previews: PreviewProvider {
    static var previews: some View {
        PageView(publication: Publication.publication1, pageNumber: 3)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationDetails Mac")
        
        PageView(publication: Publication.publication1, pageNumber: 3)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationDetails iOS")
    }
}
