//
//  PageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 15..
//

import SwiftUI

struct PageView: View {
    var number: Int
    var parity: Parity { Parity(number) }
    var isDummy: Bool = false
    @Binding var article: Article
    
    var body: some View {
        VStack {
            pageNumber
                .frame(maxWidth: .infinity,
                       maxHeight: .infinity,
                       alignment: parity == .even ? .bottomLeading : .bottomTrailing)
        }
        .frame(width: 70, height: 100)
    }
    
    @ViewBuilder var pageNumber: some View {
        Text(isDummy ? "" : String(number))
            .font(.footnote)
            .padding(.top, 3.0)
    }
    
//    @ViewBuilder var articlePageView: some View {
//        
//    }
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
        PageView(number: 51)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationDetails Mac")
        
        PageView(number: 51)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationDetails iOS")
    }
}
