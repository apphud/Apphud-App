//
//  ApphudApp.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import SwiftUI

@main
struct ApphudApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(SessionStore()).accentColor(.accentColor)
        }
    }
}

