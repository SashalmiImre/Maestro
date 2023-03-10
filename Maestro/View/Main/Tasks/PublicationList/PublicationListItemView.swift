//
//  PublicationListItemView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 01..
//

import SwiftUI
struct PublicationListItemView: View {
    var publication: Publication

    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "magazine")
                .resizable()
                .scaledToFit()
                .font(.title.weight(.light))
                .frame(height: 35)
                .foregroundColor(.secondary)
            VStack(alignment: .leading) {
                Text(publication.name)
                    .font(.headline)
                Text(publication._id.stringValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.all, 5)
    }
}


// MARK: - Previews

struct PublicationListItemView_Previews: PreviewProvider {
    static var previews: some View {
        PublicationListItemView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationListItem Mac")
        
        PublicationListItemView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationListItem iOS")
    }
}
