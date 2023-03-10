//
//  LoginView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 13..
//

import SwiftUI
import RealmSwift

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.realmApplication) var application: RealmSwift.App

    @State private var isLoggingIn = false
    @State private var error: Error?
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
        ZStack {
            LoginBackground()
                .brightness(colorScheme == .dark ? -0.5 : 0)
            
            VStack {
                Image("Maestro")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 80)
                    .blendMode(.overlay)
                    .opacity(0.7)
                
                Form {
                    TextField("",
                              text: $email,
                              prompt: Text("E-mail"))
                        .textContentType(.username)
#if os(iOS)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
#endif
                    LoginPasswordField(text: $password)
                        .formStyle(.grouped)
                }
                .formStyle(.grouped)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .padding(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                
                if isLoggingIn { ProgressView() }
                
                if self.error != nil { LoginErrorView(error: $error) }
                
                if !isLoggingIn {
                    Button("Belépés") { loggingIn() }
                        .keyboardShortcut(.return)
                }
            }
            .frame(width: 400, height: 250, alignment: .center)
        }
    }

    private func loggingIn() {
        withAnimation { isLoggingIn = true }
        Task {
            do {
                let user = try await application.login(credentials: .emailPassword(email: email, password: password))
            } catch {
                withAnimation {
                    self.error = error
                    isLoggingIn = false
                }
                return
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
