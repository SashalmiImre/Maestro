//
//  LoginErrorView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 16..
//

import SwiftUI

struct LoginErrorView: View {
    @Binding var error: Error?
    
    var body: some View {
        Text("Error: \(error?.localizedDescription ?? "")")
            .foregroundColor(.white)
            .padding(EdgeInsets(top: 0, leading: 5, bottom: 0, trailing: 5))
            .background(.black)
            .transition(.opacity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // 1 sec delay
                    withAnimation { error = nil }
                }
            }
    }
}

struct LoginErrorView_Previews: PreviewProvider {
    static var previews: some View {
        LoginErrorView(error: .constant(nil))
    }
}
