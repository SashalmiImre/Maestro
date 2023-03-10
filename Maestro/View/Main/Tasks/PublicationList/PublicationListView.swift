//
//  PublicationListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 25..
//

import SwiftUI
import RealmSwift

struct PublicationListView: View {
    private var vm = PublicationListViewModel()
    
    var body: some View {
        DisclosureGroup("Kiadványok") {
            ForEach(vm.publications, id: \.self) { publication in
                NavigationLink {
                    PublicationDetailsView(publication: publication)
                } label: {
                    PublicationListItemView(publication: publication)
                }
                .buttonStyle(.plain)
                .transition(.scale)
                .rowActions(edge: .leading) {
                    Button {
                        withAnimation {
                            vm.deletePublication(publication)
                        }
                    } label: {
                        Image(systemName: "trash.circle.fill")
                            .resizable()
                            .frame(width: 20, height: 20)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                }
                .rowActions {
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
                
            }
            Button {
                vm.add(publication: Publication())
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
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
        
        .alert("Kiadvány törlésének megerősítése",
               isPresented: vm.$showingAlert,
               presenting: vm.publicationToDelete) { publication in
            TextField(publication.name, text: vm.$typedPublicationName)
            Button("Elvetés", role: .cancel, action: {})
                .buttonStyle(.borderedProminent)
            Button("Törlés", role: .destructive) {
                guard vm.isTypedTextCorrect() else { return }
                vm.delete(publication)
            }
        } message: { publication in
            Text("Valóban törölni akarod a\(vm.isStartingWithVowel(publication.name) ? "z" : "") \(publication.name) nevű kiadványt? Ez a művelet törli az összes kapcsolódó adatot, és nem vonható vissza, épp ezért, kérlek gépeld be törölni kívánt kiadvány nevét!")
        }
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
