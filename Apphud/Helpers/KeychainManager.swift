//
//  KeychainManage.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

let kSecClassValue = NSString(format: kSecClass)
let kSecAttrAccountValue = NSString(format: kSecAttrAccount)
let kSecValueDataValue = NSString(format: kSecValueData)
let kSecClassGenericPasswordValue = NSString(format: kSecClassGenericPassword)
let kSecAttrServiceValue = NSString(format: kSecAttrService)
let kSecMatchLimitValue = NSString(format: kSecMatchLimit)
let kSecReturnDataValue = NSString(format: kSecReturnData)
let kSecMatchLimitOneValue = NSString(format: kSecMatchLimitOne)
let userAccount = "APPHUD_USER"
let keychainAccessGroupName = Constants.keyChainGroupID

public class KeychainManager: NSObject {
    static var defaults: UserDefaults {
        UserDefaults(suiteName: Constants.APP_GROUP_ID)!
    }
    static func generateUUID() -> String {
        let uuid = NSUUID.init().uuidString
        return uuid
    }

    static func loadRefreshToken() -> String? {
        if let refreshToken = defaults.value(forKey: Constants.REFRESH_TOKEN_KEY) as? String, refreshToken.count > 0 {
            return refreshToken
        }
        
        return self.load(Constants.REFRESH_TOKEN_KEY as NSString)
    }

    static func loadAccessToken() -> String? {
        if let accessToken = defaults.value(forKey: Constants.JWT_TOKEN_KEY) as? String, accessToken.count > 0 {
            return accessToken
        }
        return self.load(Constants.JWT_TOKEN_KEY as NSString)
    }

    static func resetValues() {
        saveRefreshToken(token: "")
        saveAccessToken(token: "")
    }

    public class func saveRefreshToken(token: String) {
        defaults.set(token, forKey: Constants.REFRESH_TOKEN_KEY)
        self.save(Constants.REFRESH_TOKEN_KEY as NSString, data: token)
    }

    public class func saveAccessToken(token: String) {
        defaults.set(token, forKey: Constants.JWT_TOKEN_KEY)
        self.save(Constants.JWT_TOKEN_KEY as NSString, data: token)
    }

    private class func save(_ service: NSString, data: String) {
        if let dataFromString = data.data(using: .utf8, allowLossyConversion: false) {

            let keychainQuery: NSDictionary = [
                kSecClassValue: kSecClassGenericPasswordValue,
                kSecAttrServiceValue: service,
                kSecAttrAccountValue: userAccount,
                kSecValueDataValue: dataFromString,
                kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject,
                NSString(format: kSecAttrAccessible): NSString(format: kSecAttrAccessibleAfterFirstUnlock)
            ]

            SecItemDelete(keychainQuery as CFDictionary)
            SecItemAdd(keychainQuery as CFDictionary, nil)
        }
    }

    private class func load(_ service: NSString) -> String? {

        let keychainQuery: NSDictionary = [
            kSecClassValue: kSecClassGenericPasswordValue,
            kSecAttrServiceValue: service,
            kSecAttrAccountValue: userAccount,
            kSecReturnDataValue: kCFBooleanTrue!,
            kSecMatchLimitValue: kSecMatchLimitOneValue,
            kSecAttrAccessGroup as String: keychainAccessGroupName as AnyObject,
        ]

        var dataTypeRef: AnyObject?

        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        var contentsOfKeychain: String?

        if status == errSecSuccess {
            if let retrievedData = dataTypeRef as? Data {
                contentsOfKeychain = String(data: retrievedData, encoding: .utf8)
            }
        }

        guard contentsOfKeychain?.count ?? 0 > 0 else {return nil}

        return contentsOfKeychain
    }
}
