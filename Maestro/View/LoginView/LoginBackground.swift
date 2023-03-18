//
//  LoginBackground.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 16..
//

import SwiftUI

struct LoginBackground: View {
    @State private var progress: CGFloat = 0
    let gradient1 = Gradient(colors: [.purple, .yellow])
    let gradient2 = Gradient(colors: [.blue, .purple])
    
    var body: some View {
        Rectangle()
            .animatableGradient(fromGradient: gradient1, toGradient: gradient2, progress: progress)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: true)) {
                    self.progress = 1
                }
            }
    }
}


// MARK: -Previews

struct LoginBackground_Previews: PreviewProvider {
    static var previews: some View {
        LoginBackground()
    }
}
