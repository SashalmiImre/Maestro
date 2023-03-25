//
//  DeadlineListItemView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 26..
//

import SwiftUI
import RealmSwift

struct DeadlineListItemView: View {
    @ObservedRealmObject var deadline: DeadlineProjection
    
    var body: some View {
        HStack {
            TextField("", value: $deadline.startPageNumber, formatter: Self.intFormatter)
                .multilineTextAlignment(.trailing)
                .frame(width: 30)
                .textFieldStyle(.plain)
            Text("–")
                .fixedSize()
            TextField("", value: $deadline.endPageNumber, formatter: Self.intFormatter)
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
    
    static let intFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesSignificantDigits = false
        return formatter
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
}


// MARK: - Previews

struct DeadlineListRow_Previews: PreviewProvider {
    static var previews: some View {
        DeadlineListItemView(deadline: DeadlineProjection(projecting: Deadline()))
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("DeadlineListRow Mac")
        
        DeadlineListItemView(deadline: DeadlineProjection(projecting: Deadline()))
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("DeadlineListRow iOS")
    }
}
