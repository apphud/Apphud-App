//
//  App.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

struct AHApp: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let bundleId: String?
    let packageName: String?
    let iconUrl: String?
    
    var iconURL: URL? {
        guard let url = iconUrl else { return nil }
        
        return URL(string: url)
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
    
    var intentApp: IntentApp { IntentApp(identifier: id, display: name) }

    static var mock: AHApp { AHApp(id: "fake1", name: "App Name", bundleId: "test.bundle", packageName: nil, iconUrl: "https://placehold.it/100x100") }
    
    static var mock2: AHApp { AHApp(id: "fake2", name: "VPN Some", bundleId: "test.bundle2", packageName: nil, iconUrl: "https://placehold.it/100x100") }
    
    static var mock3: AHApp { AHApp(id: "fake3", name: "Flowers Bundle Extended", bundleId: "test.bundle3", packageName: nil, iconUrl: "https://placehold.it/100x100") }
}
