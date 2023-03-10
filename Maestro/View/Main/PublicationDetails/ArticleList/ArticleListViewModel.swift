//
//  ArticleListViewModel.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 01..
//

import Foundation
import SwiftUI
import RealmSwift

extension ArticleListView {
    struct ArticleListViewModel: DynamicProperty {
        @ObservedRealmObject var publication: Publication
        
        @State var selected: Article?
        @State var isExpanded: Bool = true
        @State var showingAlert: Bool = false
        @State var selectedArticle: Article?
        @State var articleToDelete: Article?
        @State var typedArticleName: String = ""
        
        init(publication: ObservedRealmObject<Publication>) {
            self._publication = publication
        }
        
        func isStartingWithVowel(_ text: String) -> Bool {
            return "aáeéiíoóöőuúüű15_".contains { Character(text.first!.lowercased()) == $0}
        }
        
        func add(article: Article) {
            $publication.articles.append(article)
        }
        
        func deleteArticle(_ article: Article? = nil) {
            guard let articleToDelete = article ?? selectedArticle else { return }
            self.articleToDelete = articleToDelete
            showingAlert = true
        }
        
        func delete(_ article: Article) {
            guard let index = publication.articles.index(of: article) else { return }
            withAnimation {
                $publication.articles.remove(at: index)
            }
        }
        
        func isTypedTextCorrect() -> Bool {
            guard let articleName = articleToDelete?.name else { return false }
            let typedName = typedArticleName
            typedArticleName = ""
            return typedName == articleName
        }
    }
}
