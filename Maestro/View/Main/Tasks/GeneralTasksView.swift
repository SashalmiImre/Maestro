//
//  GeneralTasksView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 02..
//

import SwiftUI

struct GeneralTasksView: View {
    var body: some View {
        DisclosureGroup("Közös feladatok") {
            
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
}

struct GeneralTasksView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralTasksView()
    }
}
