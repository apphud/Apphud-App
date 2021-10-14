//
//  User.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

struct User: Codable {
    let id: String
    let email: String
    let name: String
    let avatarUrl: String

    static var mock: User { User(id: "fake", email: "1@1.com", name: "Alexander Selivanov", avatarUrl: "https://placehold.it/100x100") }
}

struct TokenPair: Codable {
    var accessToken: String
    var refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken
        case accessToken = "token"
    }
}
