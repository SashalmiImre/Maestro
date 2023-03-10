//
//  LayoutEditor.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 01. 08..
//

import SwiftUI
import GridStack

struct LayoutEditor: View {
    var body: some View {
        GridStack(
            minCellWidth: 200,
            spacing: 20,
            numItems: 26,
            alignment: .leading) { (index, cellWidth) in
                Color(.white)
                    .frame(height: 150)
            }
    }
}

struct LayoutEditor_Previews: PreviewProvider {
    static var previews: some View {
        LayoutEditor()
    }
}
