//
//  DeadlineListRowView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 26..
//

import SwiftUI
import RealmSwift

struct DeadlineListRowView: View {
    @Binding var deadline: Deadline
    
    var body: some View {
            HStack {
                TextField("", value: $deadline.startPageNumber, formatter: intFormatter)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 30)
                    .textFieldStyle(.plain)
                Text("–")
                    .fixedSize()
                TextField("", value: $deadline.endPageNumber, formatter: intFormatter)
                    .multilineTextAlignment(.leading)
                    .frame(width: 30)
                    .textFieldStyle(.plain)
                Spacer()
                DatePicker("",
                           selection: $deadline.date,
                           in: Date()...,
                           displayedComponents: [.hourAndMinute, .date])
                .fixedSize()
            }
            .font(.headline)
    }
    
    var intFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = false
        return formatter
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
}

struct DeadlineListRow_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineListRowView(deadline: .constant(Deadline()))
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("DeadlineListRow Mac")
        
        DeadlineListRowView(deadline: .constant(Deadline()))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("DeadlineListRow iOS")
    }
}
