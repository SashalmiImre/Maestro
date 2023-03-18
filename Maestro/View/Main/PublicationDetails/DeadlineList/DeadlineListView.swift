//
//  DeadlineListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 26..
//

import SwiftUI
import RealmSwift

struct DeadlineListView: View {
    @ObservedRealmObject var publication: Publication
    @State var isExpanded: Bool = true
    
    var body: some View {
        DisclosureGroup("Leadási határidők", isExpanded: $isExpanded) {
            ForEach($publication.deadlines, id: \.self) { $deadline in
                DeadlineListRowView(deadline: $deadline)
                    .transition(.scale)
                    .rowActions(edge: .leading) {
                        Button {
                            withAnimation {
                                delete(deadline: deadline)
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
            }
            .textFieldStyle(.plain)
            
            Button {
                withAnimation {
                    $publication.deadlines.append(Deadline())
                }
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                    Text("Új határidő hozzáadása")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
    
    func delete(deadline: Deadline) {
        guard let index = publication.deadlines.index(of: deadline) else { return }
        $publication.deadlines.remove(at: index)
    }
}

struct DeadlineList_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineListView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("DeadlineList Mac")
        
        DeadlineListView(publication: Publication.publication1)
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("DeadlineList iOS")
    }
}
