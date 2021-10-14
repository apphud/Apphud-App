//
//  SessionStore.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import Foundation
import Combine
import WidgetKit

enum LoginError: Error {
    case wrongCredentials
}

class SessionStore: ObservableObject {
    var didChange = PassthroughSubject<SessionStore, Never>()
    
    private var lastStartTime: String?
    private var lastEndTime: String?
    
    @Published var session: User? { didSet { didChange.send(self) } }
    @Published var apps: [AHApp] = [] { didSet { didChange.send(self) } }
    @Published var dashboard: Dashboard? { didSet { didChange.send(self) } }

    @Published var currentApp: AHApp? {
        didSet {
            didChange.send(self)
            if currentApp != nil {
                if lastStartTime != nil && lastEndTime != nil {
                    fetchDashboardFor(appID: currentApp!.id, startTime: lastStartTime!, endTime: lastEndTime!, fromWidget: false, completion: { _ in})
                } else {
                    fetchDashboardFor(appID: currentApp!.id, period: .today, fromWidget: false, completion: {_ in })
                }
            }
        }
    }
    
    @Published var loading = true
    @Published var logged = false

    private var defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: Constants.APP_GROUP_ID)!
    }
    func listen() {
        loading = true
        NetworkService.shared.me { [weak self] (user, token_pair) in
            self?.fetchApps()
            DispatchQueue.main.async {
                if let user = user {
                    AuthService.shared.saveUser(user)
                }
                self?.loading = false
                self?.logged = user != nil
                self?.session = user
            }
        }
    }

    func fetchApps() {
        NetworkService.shared.fetchApps { (apps) in
            guard let apps = apps, apps.count > 0 else { return }
            
            DispatchQueue.main.async { [weak self] in
                var app: AHApp!
                if let id = self?.currentAppID {
                    app = apps.first { (a) -> Bool in
                        a.id == id
                    }
                } else {
                    app = apps.first!
                }
                self?.selectApp(app)
                self?.apps = apps
                AppsManager.shared.saveApps(apps)
            }
        }
    }
    
    func logout() {
        KeychainManager.resetValues()
        defaults.set(nil, forKey: Constants.CURRENT_USER_KEY)
        self.loading = false
        self.logged = false
        self.session = nil
    }
        
    func login(email: String, password: String, callback: @escaping (User?, LoginError?) -> Void) {
        NetworkService.shared.login(email: email, password: password) { [weak self] (user, pair) in
            guard let self = self else { return }
            
            DispatchQueue.main.async { [weak self] in
                self?.logged = user != nil
                self?.session = user
            }
            if let pair = pair, let user = user {
                AuthService.shared.saveTokens(pair)
                AuthService.shared.saveUser(user)
                callback(user, nil)
            } else {
                callback(nil, LoginError.wrongCredentials)
            }
        }
    }
    
    var currentAppID: String? {
        defaults.string(forKey: Constants.CURRENT_APP_KEY)
    }
    
    func selectApp(_ app: AHApp) {
        defaults.setValue(app.id, forKey: Constants.CURRENT_APP_KEY)
        self.currentApp = app
    }

    func fetchDashboardFor(appID: String, period: IntentPeriod, fromWidget: Bool, completion: @escaping (Dashboard?) -> Void) {
        
        let startTime: String
        var endTime: String = Date().endOfDay.utcString
        
        switch period {
        case .today, .unknown:
            startTime = Date().startOfDay.utcString
        case .yesterday:
            startTime = Date().daysFromNow(-1).startOfDay.utcString
            endTime = Date().daysFromNow(-1).endOfDay.utcString
        case .week:
            startTime = Date().daysFromNow(-7).utcString
        case .four_weeks:
            startTime = Date().daysFromNow(-28).utcString
        case .three_months:
            startTime = Date().monthsFromNow(-3).startOfMonth.utcString
            endTime = Date().monthsFromNow(-1).endOfMonth.utcString
        case .year:
            startTime = Date().daysFromNow(-365).utcString
        case .lifetime:
            startTime = Date().daysFromNow(-3650).utcString
        }

        fetchDashboardFor(appID: appID, startTime: startTime, endTime: endTime, fromWidget: fromWidget, completion: completion)
    }
    
    func fetchDashboardFor(appID: String, startTime: String, endTime: String, fromWidget: Bool, completion: @escaping (Dashboard?) -> Void) {
        self.lastStartTime = startTime
        self.lastEndTime = endTime
        NetworkService.shared.fetchDashboard(appId: appID, startTime: startTime, endTime: endTime) { dash in
            DispatchQueue.main.async { [weak self] in
                self?.dashboard = dash
                if !fromWidget {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                completion(dash)
            }
        }
    }
}
