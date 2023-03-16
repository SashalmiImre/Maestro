//
//  MainView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 16..
//

import SwiftUI

struct MainView: View {
    
    var body: some View {
        NavigationSplitView {
            TasksView()
        } content: {
            Text("articles")
        } detail: {
            LayoutEditorView(publication: Publication.publication1)
        }
        .navigationSplitViewStyle(.prominentDetail)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
