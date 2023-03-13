//
//  RealmSyncView.swift
//  Maestro
//
//  Created by Sashalmi Imre on 2022. 12. 13..
//

import SwiftUI
import RealmSwift
import Combine

struct RealmView<Login, Connect, Content, Progress, Error>: View
where Login: View, Connect: View, Content: View, Progress: View, Error: View {
    
    private var viewModel = RealmView.RealmViewModel()
    private var login:    () -> Login
    private var connect:  () -> Connect
    private var content:  () -> Content
    private var progress: (Foundation.Progress) -> Progress
    private var error:    (Swift.Error) -> Error
    
    @Environment(\.realmManager) var realmManager: RealmManager
    @Environment(\.realmApplication) var application: RealmSwift.App
    @Environment(\.realm) var realm: Realm
    @Environment(\.realmConfiguration) var configuration: Realm.Configuration


    // MARK: - Body
    
    var body: some View {
        VStack {
            if ProcessInfo.isPreview {
                content()
            } else if application.currentUser == nil {
                login()
            } else {
                viewSelection
            }
            Text(viewModel.realmErrorMessage ?? "")
                .padding()
                .onReceive(realmManager.errorMessage) { message in
                    viewModel.realmErrorMessage = message
                }
        }
    }
    
    @ViewBuilder
    private var viewSelection: some View {
        switch viewModel.autoOpen {
            
        case .connecting:
            connect()
            
        case .waitingForUser:
            login()
            
        case .open(let realm):
            content()
                .environment(\.realm, realm)

        case .progress(let progress):
            self.progress(progress)
            
        case .error(let error):
            self.error(error)
        }
    }
    
    
    // MARK: - Initialization
    
    init(login:    @escaping () -> Login,
         connect:  @escaping () -> Connect = { ProgressView("Connecting") },
         content:  @escaping () -> Content,
         progress: @escaping (Foundation.Progress) -> Progress  = { progress in ProgressView(progress) },
         error:    @escaping (Swift.Error) -> Error = { error in Text(error.localizedDescription) }) {
        self.login    = login
        self.connect  = connect
        self.content  = content
        self.progress = progress
        self.error    = error
        
//        realmManager.errorMessage.sink { error in
//
//        } receiveValue: { errorMessage in
//            viewModel.realmErrorMessage = errorMessage
//        }
//        .store(in: &self.viewModel.subscriptions)

    }
}


struct RealmView_macOS_Previews: PreviewProvider {

    static var previews: some View {
        RealmView {
            LoginView()
        } content: {
            MainView()
        }
        
        RealmView {
            LoginView()
        } content: {
            MainView()
        }
        .previewDevice(PreviewDevice(rawValue: "iPhone 14"))
        .previewDisplayName("Realm View iPhone 14")
    }
}
