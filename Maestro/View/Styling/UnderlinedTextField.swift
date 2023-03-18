//
//  UnderlinedTextField.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 14..
//

import SwiftUI

struct UnderlinedTextField<F, V>: View where F: ParseableFormatStyle, F.FormatInput == V, F.FormatOutput == String {
    @Binding var value: V
    private  var prompt: String
    private  var formatter: F

    var body: some View {
        let text: Binding<String> = Binding(get: { self.formatter.format(self.value) },
                                            set: { self.value = try! self.formatter.parseStrategy.parse($0) })

        TextField(prompt, text: text)
            .textFieldStyle(.plain)
            .underlinedControl(prompt: prompt, isEmpty: text.wrappedValue.isEmpty)
    }
    
    init(value: Binding<V>, prompt: String, format: F) {
        self._value = value
        self.prompt = prompt
        self.formatter = format
    }
}


// MARK: - Previews

struct UnderlinedTextField_Previews: PreviewProvider {
    
    static var previews: some View {
        UnderlinedTextField(value: .constant(25), prompt: "Név", format: IntegerFormatStyle<Int>.number)
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("UnderlinedTextField Mac")
        
        UnderlinedTextField(value: .constant("Teszt"), prompt: "Név", format: StringFormatStyle())
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("UnderlinedTextField iOS")
    }
}
