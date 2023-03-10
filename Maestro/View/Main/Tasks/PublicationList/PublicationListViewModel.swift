//
//  PublicationListViewModel.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 04..
//

import SwiftUI
import RealmSwift

extension PublicationListView {
    struct PublicationListViewModel: DynamicProperty {
        @ObservedResults(Publication.self) var publications: Results<Publication>
        
        @State var showingAlert: Bool = false
        @State var selectedPublication: Publication?
        @State var publicationToDelete: Publication?
        @State var typedPublicationName: String = ""

        func delete(_ publication: Publication) {
            withAnimation { $publications.remove(publication) }
        }
        
        func isStartingWithVowel(_ text: String) -> Bool {
            return "aáeéiíoóöőuúüű15_".contains { Character(text.first!.lowercased()) == $0}
        }
        
        func add(publication: Publication) {
            $publications.append(publication)
        }
        
        func deletePublication(_ publication: Publication? = nil) {
            guard let publicationToDelete = publication ?? selectedPublication else { return }
            self.publicationToDelete = publicationToDelete
            showingAlert = true
        }
        
        func isTypedTextCorrect() -> Bool {
            guard let publicationName = publicationToDelete?.name else { return false }
            let typedName = typedPublicationName
            typedPublicationName = ""
            return typedName == publicationName
        }
    }
}
