//
//  AppsManager.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import Foundation
import WidgetKit

class AppsManager {
    static let shared = AppsManager()
    private var apps = [AHApp]()
    private var defaults: UserDefaults
    private init() {
        defaults = UserDefaults(suiteName: Constants.APP_GROUP_ID)!
    }

    func findApp(_ id: String) -> AHApp? {
        return getIntentApps().last(where: { (app) -> Bool in
            app.id == id
        })
    }

    func fetchApps(completion: @escaping ([AHApp]?) -> Void) {
        NetworkService.shared.fetchApps { (apps) in
            completion(apps)
        }
    }
    
    var currentApp: AHApp? {
        guard apps.count > 0 else { return nil }
        
        let id = defaults.string(forKey: Constants.CURRENT_APP_KEY)
        
        if let curr = apps.last(where: { (app) -> Bool in
            app.id == id
        }) {
            return curr
        }
        
        return apps.first
    }
    
    func selectApp(_ app: AHApp) {
        saveObject(app, key: Constants.CURRENT_APP_KEY)
        WidgetCenter.shared.reloadAllTimelines()
    }

    func saveApps(_ items: [AHApp]) {
        saveList(items, key: Constants.APPS_LIST_KEY)
    }
    
    private func saveList<T: Encodable>(_ items: [T], key: String) {
        if let data = try? PropertyListEncoder().encode(items) {
            defaults.set(data, forKey: key)
            defaults.synchronize()
        }
    }
    
    private func saveObject<T: Encodable>(_ item: T, key: String) {
        let encoder = JSONEncoder()
        
        if let encoded = try? encoder.encode(item) {
            defaults.set(encoded, forKey: key)
        }
    }

    func getIntentApps() -> [AHApp] {
        var apps: [AHApp] = []

        if let data = defaults.object(forKey: Constants.APPS_LIST_KEY) as? Data,
           let arr = try? PropertyListDecoder().decode([AHApp].self, from: data) {
            apps.append(contentsOf: arr)
        }

        return apps
    }
}
