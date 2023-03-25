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
            ForEach($publication.deadlines, id: \.self) { deadline in
                DeadlineListItemView(deadline: DeadlineProjection(projecting: deadline.wrappedValue))
                    .transition(.scale)
                    .rowActions(edge: .leading) {
                        deleteButton(target: deadline.wrappedValue)
                    }
            }
            .textFieldStyle(.plain)
            appendButton()
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
    
    
    // MARK: - Buttons
    
    @ViewBuilder
    private func deleteButton(target: Deadline) -> some View {
        Button {
            delete(deadline: target)
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
    private func appendButton() -> some View {
        Button {
            add(deadline: Deadline())
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
    
    
    // MARK: - Functions
    
    private func add(deadline: Deadline) {
        withAnimation { $publication.deadlines.append(deadline) }
    }
    
    private func delete(deadline: Deadline) {
        guard let index = publication.deadlines.firstIndex(of: deadline) else { return }
        withAnimation { $publication.deadlines.remove(at: index) }
    }
}


// MARK: - Previews

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
