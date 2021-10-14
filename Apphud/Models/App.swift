//
//  App.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

struct AHApp: Codable, Identifiable {
    let id: String
    let name: String
    let bundleId: String?
    let packageName: String?
    let iconUrl: String?
    
    var iconURL: URL? {
        guard let url = iconUrl else { return nil }
        
        return URL(string: url)
    }
    var intentApp: IntentApp { IntentApp(identifier: id, display: name) }

    static var mock: AHApp { AHApp(id: "fake", name: "Example App", bundleId: "test.bundle", packageName: nil, iconUrl: "https://placehold.it/100x100") }
}
