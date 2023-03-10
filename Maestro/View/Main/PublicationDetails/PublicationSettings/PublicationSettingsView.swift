//
//  PublicationSettingsView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 26..
//

import SwiftUI
import RealmSwift

struct PublicationSettingsView: View {
    @ObservedRealmObject var publication: Publication
    @State private var isExpanded: Bool = true
    
    var body: some View {
        DisclosureGroup("Beállítások", isExpanded: $isExpanded) {
            HStack(alignment: .bottom) {
                UnderlinedTextField(value: $publication.name, prompt: "Név", format: StringFormatStyle())
                    .frame(minWidth: 180)
                
                Divider()
                
                UnderlinedTextField(value: $publication.version, prompt: "Terjedelem", format: StringFormatStyle())
                
                Divider()
                
                UnderlinedTextField(value: $publication.version, prompt: "Verzió", format: StringFormatStyle())
            }
            
            HStack {
                DatePicker("",
                           selection: $publication.publicationDate,
                           in: Date()...,
                           displayedComponents: .date)
                .datePickerStyle(.compact)
                .underlinedControl(prompt: "Megjelenés:")
                
                Divider()
                
                Toggle("", isOn: $publication.isSpecialIssue)
                    .toggleStyle(.switch)
                    .tint(.accentColor)
                    .underlinedControl(prompt: "Különszám:")
            }
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
}

struct PublicationSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        PublicationSettingsView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationSettings Mac")
        
        PublicationSettingsView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationSettings iOS")
    }
}
