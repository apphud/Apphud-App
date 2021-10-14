//
//  AuthService.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Combine
import Foundation
import WidgetKit

class AuthService: ObservableObject {
    static let shared = AuthService()
    
    var currentUser: User? {
        if let savedPerson = defaults.object(forKey: Constants.CURRENT_USER_KEY) as? Data {
            let decoder = JSONDecoder()
            if let loadedPerson = try? decoder.decode(User.self, from: savedPerson) {
                return loadedPerson
            }
        }
        
        return nil
    }
    
    let didChange = PassthroughSubject<AuthService,Never>()

    // required to conform to protocol 'ObservableObject'
    let willChange = PassthroughSubject<AuthService,Never>()
    var defaults: UserDefaults
    private init() {
        defaults = UserDefaults(suiteName: Constants.APP_GROUP_ID)!
    }
    
    var accessToken: String {
        KeychainManager.loadAccessToken() ?? ""
    }
       
    var refreshToken: String {
        KeychainManager.loadRefreshToken() ?? ""
    }
    
    func saveTokens(_ pair: TokenPair) {
        KeychainManager.saveAccessToken(token: pair.accessToken)
        KeychainManager.saveRefreshToken(token: pair.refreshToken)
    }
    
    func saveUser(_ user: User) {
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(user) {
            defaults.set(encoded, forKey: Constants.CURRENT_USER_KEY)
        }
        
        WidgetCenter.shared.reloadAllTimelines()
    }
}
