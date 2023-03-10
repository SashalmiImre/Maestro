//
//  UnderlinedControl.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 24..
//

import SwiftUI

struct UnderlinedControl: ViewModifier {
    var prompt: String
    var isEmpty: Bool
    
    func body(content: Content) -> some View {
        VStack(alignment: .leading) {
            if !isEmpty {
                Text(prompt.uppercased())
                    .truncationMode(.tail)
                    .lineLimit(1)
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
            content
                .font(.headline)
                .overlay(alignment: .bottom) {
                    Divider()
                        .offset(x: 0, y: 5)
                }
        }
        .padding([.top, .bottom], 5)
        .animation(.easeIn, value: isEmpty)
        }
}


// MARK: - View extension

extension View {
    func underlinedControl(prompt: String, isEmpty: Bool = false) -> some View {
        modifier(UnderlinedControl(prompt: prompt, isEmpty: isEmpty))
    }
}


// MARK: - Preview

struct UnderlinedControl_Previews: PreviewProvider {
    static var previews: some View {
        TextField("", text: .constant("Teszt"))
            .textFieldStyle(.plain)
            .underlinedControl(prompt: "Prompt")
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("PublicationDetails Mac")
        
        TextField("", text: .constant("Teszt"))
            .textFieldStyle(.plain)
            .underlinedControl(prompt: "Prompt")
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("PublicationDetails iOS")
    }
}

