//
//  DeadlineListView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 26..
//

import SwiftUI
import RealmSwift

struct DeadlineListView: View {
    private var vm: DeadlineListViewModel
    
    var body: some View {
        DisclosureGroup("Leadási határidők", isExpanded: vm.$isExpanded) {
            ForEach(vm.$publication.deadlines, id: \.self) { $deadline in
                DeadlineListRowView(deadline: $deadline)
                    .transition(.scale)
                    .rowActions(edge: .leading) {
                        Button {
                            withAnimation {
                                vm.delete(deadline: deadline)
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
                    vm.$publication.deadlines.append(Deadline())
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
    
    init(publication: ObservedRealmObject<Publication>) {
        self.vm = DeadlineListViewModel(publication: publication)
    }
}

struct DeadlineList_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineListView(publication: ObservedRealmObject<Publication>(wrappedValue: Publication.publication1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("DeadlineList Mac")
        
        DeadlineListView(publication: ObservedRealmObject<Publication>(wrappedValue: Publication.publication1))
            .padding()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("DeadlineList iOS")
    }
}
