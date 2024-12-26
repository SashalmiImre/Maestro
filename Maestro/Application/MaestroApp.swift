//
//  MaestroApp.swift
//  Maestro
//
//  Created by Sashalmi Imre on 04/12/2024.
//
//  A Maestro alkalmazás belépési pontja. Ez a fájl tartalmazza az alkalmazás
//  fő struktúráját és a kezdeti nézet beállítását.

import SwiftUI

/// A Maestro alkalmazás fő típusa
/// Felelős az alkalmazás életciklusának kezeléséért és a fő nézet megjelenítéséért
@main
struct MaestroApp: App {
    /// Az alkalmazás fő nézethierarchiájának definíciója
    /// - Returns: Egy Scene objektum, amely az alkalmazás fő ablakát reprezentálja
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
