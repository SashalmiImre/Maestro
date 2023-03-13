//
//  ArticleListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 30..
//

import SwiftUI
import RealmSwift

struct ArticleListView: View {
    private var vm: ArticleListViewModel
    
    var body: some View {
        DisclosureGroup("Cikkek", isExpanded: vm.$isExpanded) {
            ForEach(vm.$publication.articles, id: \.self) { (article: Binding<Article>) in
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
               isPresented: vm.$showingAlert,
               presenting: vm.articleToDelete) { article in
            TextField(article.name, text: vm.$typedArticleName)
            Button("Elvetés", role: .cancel, action: {})
                .buttonStyle(.borderedProminent)
            Button("Törlés", role: .destructive) {
                guard vm.isTypedTextCorrect() else { return }
                vm.delete(article)
            }
        } message: { article in
            Text("Valóban törölni akarod a\(vm.isStartingWithVowel(article.name) ? "z" : "") \(article.name) nevű cikket? Ez a művelet törli az összes kapcsolódó adatot, és nem vonható vissza, épp ezért, kérlek gépeld be törölni kívánt kiadvány nevét!")
        }
    }
    
    init(publication: ObservedRealmObject<Publication>) {
        self.vm = ArticleListViewModel(publication: publication)
    }
    
    
    // MARK: - Buttons
    
    @ViewBuilder
    private func deleteButton(target: Article) -> some View {
        Button {
            vm.deleteArticle(target)
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
                vm.$publication.articles.append(Article())
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
}


// MARK: - Previews

struct ArticleListView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleListView(publication: ObservedRealmObject<Publication>(wrappedValue: Publication.publication1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("ArticleList Mac")
        
        ArticleListView(publication: ObservedRealmObject<Publication>(wrappedValue: Publication.publication1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("ArticleList iOS")
    }
}
