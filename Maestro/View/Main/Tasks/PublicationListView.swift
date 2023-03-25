//
//  PublicationListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 25..
//

import SwiftUI
import RealmSwift

struct PublicationListView: View {
    @ObservedResults(Publication.self) var publications
    
    @State var showingAlert: Bool = false
    @State var selectedPublication: Publication?
    @State var textToConfirmation: String = ""

    
    var body: some View {
        DisclosureGroup("Kiadványok") {
            ForEach(publications, id: \.self) { publication in
                    NavigationLink {
                        PublicationDetailsView(publication: publication)
                    } label: {
                        PublicationListItemView(publication: publication)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale)
                    .rowActions(edge: .leading) { deleteButton(target: publication) }
                    .rowActions { validateButton(target: publication) }
                }
            appendButton()
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
        
        .alert("Kiadvány törlésének megerősítése",
               isPresented: $showingAlert,
               presenting: selectedPublication) { publication in
            TextField(publication.name, text: $textToConfirmation)
            Button("Elvetés", role: .cancel) { }
                .buttonStyle(.borderedProminent)
            Button("Törlés", role: .destructive) {
                guard isTypedTextCorrect() else { return }
                delete(publication)
            }
        } message: { publication in
            Text("Valóban törölni akarod a\(publication.name.isStartingWithVowel() ? "z" : "") \(publication.name) nevű kiadványt? Ez a művelet törli az összes kapcsolódó adatot, és nem vonható vissza, épp ezért, kérlek gépeld be törölni kívánt kiadvány nevét!")
        }
    }
    
    
    // MARK: - Buttons
    
    @ViewBuilder
    private func deleteButton(target: Publication) -> some View {
        Button {
            selectedPublication = target
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
    private func validateButton(target: Publication) -> some View {
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
            add(publication: Publication())
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .foregroundColor(.accentColor)
                Text("Új kiadvány hozzáadása")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
    
    
    // MARK: - Functions
    
    func add(publication: Publication) {
        $publications.append(publication)
    }
    
    func delete(_ publication: Publication) {
        withAnimation { $publications.remove(publication) }
    }

    func isTypedTextCorrect() -> Bool {
        guard let publicationName = selectedPublication?.name else { return false }
        return textToConfirmation == publicationName
    }
}


// MARK: - Previews

struct PublicationsListView_Previews: PreviewProvider {
    static var previews: some View {
        PublicationListView()
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationListView Mac")
        
        PublicationListView()
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationListView iOS")
    }
}
