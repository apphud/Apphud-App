//
//  IntentHandler.swift
//  ApphudIntentHandler
//
//  Created by Alexander Selivanov on 06.10.2020.
//

import Intents

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        switch intent {
        case is ConfigurationIntent:
            return Handler()
        default:
            return self
        }
    }
    
}
class BaseIntentHandler: NSObject {
    func prepareAppsObjects() -> INObjectCollection<IntentApp>? {
        let apps = AppsManager.shared.getIntentApps()
        let intentApps = apps.map({ (app) -> IntentApp in
            app.intentApp
        })
        return INObjectCollection(items: intentApps)
    }
    
    @objc(defaultAppForConfiguration:) func defaultApp(for intent: ConfigurationIntent) -> IntentApp? {
        guard let app = SessionStore().currentApps?.first else { return nil }
        
        return IntentApp(identifier: app.id, display: app.name)
    }
}

class Handler: BaseIntentHandler, ConfigurationIntentHandling {
    func provideAppOptionsCollection(for intent: ConfigurationIntent, with completion: @escaping (INObjectCollection<IntentApp>?, Error?) -> Void) {
        completion(prepareAppsObjects(), nil)
    }
    
    func confirm(intent: ConfigurationIntent, completion: @escaping (ConfigurationIntentResponse) -> Void) {
        if intent.app?.count ?? 0 > 10 {
            let response = ConfigurationIntentResponse(code: .failure, userActivity: nil)
            completion(response)
        } else {
            let response = ConfigurationIntentResponse(code: .success, userActivity: nil)
            completion(response)
        }
    }
}
