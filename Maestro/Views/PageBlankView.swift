//
//  BlankPageView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 27/12/2024.
//

import SwiftUI

/// Üres oldal
struct PageBlankView: View {
    let scale: CGFloat
    let defaultSize: CGSize
    var body: some View {
        Color.clear
            .frame(width: defaultSize.width * scale, height: defaultSize.height * scale)
    }
}
