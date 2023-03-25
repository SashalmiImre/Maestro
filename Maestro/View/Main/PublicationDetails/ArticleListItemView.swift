//
//  ArticleListItemView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 08..
//

import SwiftUI
import RealmSwift

struct ArticleListItemView: View {
    @Binding var article: Article

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "doc")
                .resizable()
                .scaledToFit()
                .font(.title.weight(.light))
                .frame(height: 35)
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(article.name)
                    .font(.headline)
                Text(article.mode.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Divider()
            Text("InProgress")
                .font(.caption2)
        }
        .padding(.all, 5)
    }
}


// MARK: - Previews

struct ArticleListItemView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListItemView(article: .constant(Article.article1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("ArticleListItem Mac")
        
        ArticleListItemView(article: .constant(Article.article1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("ArticleListItem iOS")
    }
}
