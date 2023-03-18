//
//  ArticleListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 30..
//

import SwiftUI
import RealmSwift

struct ArticleListView: View {
    @ObservedRealmObject var publication: Publication

    @State var isExpanded: Bool = true
    @State var showingAlert: Bool = false
    @State var selectedArticle: Article?
    @State var articleToDelete: Article?
    @State var typedArticleName: String = ""
    
    var body: some View {
        DisclosureGroup("Cikkek", isExpanded: $isExpanded) {
            ForEach($publication.articles, id: \.self) { (article: Binding<Article>) in
#if os(macOS)
                ArticleListItemView(article: article)
                    .transition(.scale)
                    .rowActions(edge: .leading) {
                        deleteButton(target: article.wrappedValue)
                    }
                    .rowActions {
                        validateButton(target: article.wrappedValue)
                    }
                
#elseif os(iOS)
                NavigationLink {
                    ArticleDetailsView()
                } label: {
                    ArticleListItemView(article: article)
                }
                .transition(.scale)
                .rowActions(edge: .leading) {
                    deleteButton(target: article.wrappedValue)
                }
                .rowActions {
                    validateButton(target: article.wrappedValue)
                }
                
#endif
            }
            
            appendButton()
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
        .alert("Cikk törlésének megerősítése",
               isPresented: $showingAlert,
               presenting: articleToDelete) { article in
            TextField(article.name, text: $typedArticleName)
            Button("Elvetés", role: .cancel, action: {})
                .buttonStyle(.borderedProminent)
            Button("Törlés", role: .destructive) {
                guard isTypedTextCorrect() else { return }
                delete(article)
            }
        } message: { article in
            Text("Valóban törölni akarod a\(article.name.isStartingWithVowel() ? "z" : "") \(article.name) nevű cikket? Ez a művelet törli az összes kapcsolódó adatot, és nem vonható vissza, épp ezért, kérlek gépeld be törölni kívánt kiadvány nevét!")
        }
    }

    
    
    // MARK: - Buttons
    
    @ViewBuilder
    private func deleteButton(target: Article) -> some View {
        Button {
            deleteArticle(target)
        } label: {
            Image(systemName: "trash.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .red)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func validateButton(target: Article) -> some View {
        Button {
            
        } label: {
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 20, height: 20)
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .blue)
        }
        .buttonStyle(.plain)
    }
    
    
    @ViewBuilder
    private func appendButton() -> some View {
        Button {
            withAnimation {
                $publication.articles.append(Article())
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Új cikk hozzáadása")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
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
        guard let index = publication.articles.firstIndex(of: article) else { return }
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


// MARK: - Previews

struct ArticleListView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("ArticleList Mac")
        
        ArticleListView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("ArticleList iOS")
    }
}
