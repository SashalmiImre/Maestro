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
            Button("AppleEvent") {
//                do {
////                    let sdefURL = Bundle.main.url(forResource: "Adobe InDesign 2023", withExtension: "sdef")!
////                    let data = try readSDEF(from: sdefURL)
//                    let app = try IDApplication()
//                    let docURL = Bundle.main.url(forResource: "empty", withExtension: "indd")!
//                    let doc = try app.openDocument(at: docURL)
//                    let report = try doc.report()
//                    print(report)
//                } catch {
//                    print(error)
//                }
            }
        }
        .disclosureGroupStyle(SectionDisclosureGroupStyle())
    }
}


struct UserTasksView_Previews: PreviewProvider {
    static var previews: some View {
        UserTasksView()
    }
}
