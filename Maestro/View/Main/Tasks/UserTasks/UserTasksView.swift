//
//  UserTasksView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 02..
//

import SwiftUI

struct UserTasksView: View {
    var body: some View {
        DisclosureGroup("Feladataim") {
            
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
}


struct UserTasksView_Previews: PreviewProvider {
    static var previews: some View {
        UserTasksView()
    }
}
