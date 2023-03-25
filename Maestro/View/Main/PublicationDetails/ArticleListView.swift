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
    @State var textToConfirmation: String = ""
    
    
    var body: some View {
        DisclosureGroup("Cikkek", isExpanded: $isExpanded) {
            ForEach($publication.articles, id: \.self) { article in
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
               presenting: selectedArticle) { article in
            TextField(article.name, text: $textToConfirmation)
            Button("Elvetés", role: .cancel) { }
                .buttonStyle(.borderedProminent)
            Button("Törlés", role: .destructive) {
                guard isTypedTextCorrect() else { return }
                delete(article: article)
            }
        } message: { article in
            Text("Valóban törölni akarod a\(article.name.isStartingWithVowel() ? "z" : "") \(article.name) nevű cikket? Ez a művelet törli az összes kapcsolódó adatot, és nem vonható vissza, épp ezért, kérlek gépeld be törölni kívánt kiadvány nevét!")
        }
    }

    
    // MARK: - Buttons
    
    @ViewBuilder
    private func deleteButton(target: Article) -> some View {
        Button {
            selectedArticle = target
            showingAlert = true
            textToConfirmation = ""
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
                add(article: Article())
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
    
    
    // MARK: - Functions
    
    private func add(article: Article) {
        withAnimation { $publication.articles.append(article) }
    }
    
    private func delete(article: Article) {
        guard let index = publication.articles.firstIndex(of: article) else { return }
        withAnimation { $publication.articles.remove(at: index) }
    }
    
    private func isTypedTextCorrect() -> Bool {
        guard let articleName = selectedArticle?.name else { return false }
        return textToConfirmation == articleName
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
