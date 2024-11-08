//
//  ODCApp.swift
//  ODC
//
//  Created by Erik Basargin on 06/10/2024.
//

import SwiftUI

@main
struct ODCApp: App {
    var body: some Scene {
        MenuBarExtra("ODC Lite", systemImage: "hat.widebrim.fill") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}
