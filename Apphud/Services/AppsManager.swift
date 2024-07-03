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
    
    func findApps(_ ids: [String]) -> [AHApp] {
        return getIntentApps().filter({ ids.contains($0.id) })
    }


    func fetchApps(completion: @escaping ([AHApp]?) -> Void) {
        NetworkService.shared.fetchApps { (apps) in
            completion(apps)
        }
    }
    
    var currentApps: [AHApp]? {
        guard apps.count > 0 else { return nil }
        
        let ids = defaults.string(forKey: Constants.CURRENT_APPS_KEY)
        
        var idsArray = ids?.components(separatedBy: ",")
        
        return apps.filter({ idsArray?.contains($0.id) ?? false })
    }
    
    func selectApps(_ apps: [AHApp]) {
        defaults.set(apps.map { $0.id }.joined(separator: ","), forKey: Constants.CURRENT_APPS_KEY)
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
    
    func getIntentApps() -> [AHApp] {
        var apps: [AHApp] = []

        if let data = defaults.object(forKey: Constants.APPS_LIST_KEY) as? Data,
           let arr = try? PropertyListDecoder().decode([AHApp].self, from: data) {
            apps.append(contentsOf: arr)
        }

        return apps
    }
}
