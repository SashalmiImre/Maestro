//
//  LoginPasswordField.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 17..
//

import SwiftUI

struct LoginPasswordField: View {
    @State var showPassword: Bool = false
    @Binding var text: String
    
    var body: some View {
        #if os(macOS)
        if showPassword {
            TextField(text: $text,
                      prompt: Text("Jelszó"),
                      label: showHideButton)
            .modifier(LoginFiledModifier())
        } else {
            SecureField(text: $text,
                        prompt: Text("Jelszó"),
                        label: showHideButton)
            .modifier(LoginFiledModifier())
        }
        #else
        HStack(alignment: .firstTextBaseline) {
            if showPassword {
                TextField("Jelszó", text: $text)
                    .modifier(LoginFiledModifier())
            } else {
                SecureField("Jelszó", text: $text)
                    .modifier(LoginFiledModifier())
            }
            showHideButton()
        }
        #endif
    }
    
    @ViewBuilder
    func showHideButton() -> some View {
        Button(action: {
            withAnimation { showPassword.toggle() }
        }, label: {
            Image(systemName: self.showPassword ? "eye.slash.fill" : "eye.fill")
                .foregroundColor(.secondary)
        })
        .buttonStyle(.plain)
    }
    
    
    private struct LoginFiledModifier: ViewModifier {
        
        func body(content: Content) -> some View {
            content
                .disableAutocorrection(true)
                .formStyle(.grouped)
                .textContentType(.password)
                .padding(EdgeInsets())
    #if os(iOS)
                .autocapitalization(.none)
    #endif
        }
    }
}


struct LoginPasswordField_Previews: PreviewProvider {
    static var previews: some View {
        LoginPasswordField(text: .constant("PASSWORD"))
    }
}
