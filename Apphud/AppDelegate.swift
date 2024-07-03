//
//  AppDelegate.swift
//  Apphud
//
//  Created by Renat Kurbanov on 10.06.2024.
//

import Foundation
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        UITableView.appearance().separatorStyle = .none
        UITableViewCell.appearance().backgroundColor = .green
        UITableView.appearance().backgroundColor = .green
        
        return true
    }
}
