//
//  PublicationDetailsView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 01..
//

import SwiftUI
import RealmSwift

struct PublicationDetailsView: View {
    @ObservedRealmObject var publication: Publication
    
    @State private var settingsGroupIsExpanded: Bool = true
    @State private var deadlineListGroupIsExpanded: Bool = true
    @State private var selectedDeadline: Deadline?
    
    var body: some View {
#if os(macOS)
        content
            .navigationTitle(publication.name)
#elseif os(iOS)
        TabView {
            content
                .tabItem { Label("Lista nézet", systemImage: "list.dash") }
            
            LayoutEditor()
                .tabItem { Label("Elrendezés nézet", systemImage: "rectangle.grid.2x2") }
        }
        .navigationTitle(publication.name)
#endif
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView(.vertical) {
            PublicationSettingsView(publication: publication)
                .padding()
            
            DeadlineListView(publication: self._publication)
                .padding()
            
            ArticleListView(publication: self._publication)
                .padding()
        }
    }
}



// MARK: - Preview

struct PublicationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PublicationDetailsView(publication: Publication.publication1)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationDetails Mac")
        
        PublicationDetailsView(publication: Publication.publication1)
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationDetails iOS")
    }
}
