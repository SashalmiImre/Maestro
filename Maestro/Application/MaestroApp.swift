// 
//  MaestroApp.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//
//  A Maestro alkalmazás belépési pontja. Ez a fájl tartalmazza az alkalmazás
//  fő struktúráját és a kezdeti nézet beállítását.

import SwiftUI

@main
struct MaestroApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            MainMenu()
        }
    }
}
