//
//  TasksView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2023. 02. 02..
//

import SwiftUI

struct TasksView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Image("MaestroHead")
                .resizable()
                .frame(width: 130, height: 130)
                .scaledToFit()
                .padding()


            Group {
#if os(macOS)
                Text("Feladatok")
                    .font(.title)
                    .fontWeight(.bold)
#endif
                Text("Itt találhatók az aktuális feladatok, különböző szempontok szerint csoportosítva")
                    .lineLimit(nil)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()

            
            PublicationListView()
                .padding()
            
            UserTasksView()
                .padding()
            
            GeneralTasksView()
                .padding()
            
            Spacer()
        }
        .navigationTitle("Feladatok")
    }
}


// MARK: - Previews

struct TasksView_Previews: PreviewProvider {
    static var previews: some View {
        TasksView()
            .previewDevice(PreviewDevice(rawValue: "Mac"))
            .previewDisplayName("Tasks Mac")
        
        TasksView()
            .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
            .previewDisplayName("Tasks iOS")
    }
}
