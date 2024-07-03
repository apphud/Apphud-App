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

    var isLoading = false
    
    @Published var currentApps: [AHApp]? {
        didSet {
            didChange.send(self)
            if currentApps != nil && !isMock {
                if lastStartTime != nil && lastEndTime != nil {
                    fetchDashboardsFor(appIDs: currentApps!.map { $0.id }, startTime: lastStartTime!, endTime: lastEndTime!, fromWidget: false, completion: { _ in})
                } else {
                    fetchDashboardsFor(appIDs: currentApps!.map { $0.id }, period: .today, fromWidget: false, completion: {_ in })
                }
            }
        }
    }
    
    var isMock = false
    
    static func mock() -> SessionStore {
        let store = SessionStore()
        store.isMock = true
        store.apps = [AHApp.mock, AHApp.mock2, AHApp.mock3]
        store.currentApps = [AHApp.mock, AHApp.mock2, AHApp.mock3]
        store.dashboard = Dashboard.mock()
        return store
    }
    
    @Published var loading = true
    @Published var logged = false

    private var defaults: UserDefaults
    init() {
        defaults = UserDefaults(suiteName: Constants.APP_GROUP_ID)!
    }
    func listen() {
        if isMock {return}
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
        if isMock {return}
        
        NetworkService.shared.fetchApps { (apps) in
            guard let apps = apps, apps.count > 0 else { return }
            
            DispatchQueue.main.async { [weak self] in
                var selectedApps: [AHApp]?
                
                if let ids = self?.currentAppIDs {
                    selectedApps = apps.filter({ ids.contains($0.id) })
                } else if let app = apps.first {
                    selectedApps = [app]
                }
                
                if self?.currentApps == nil {
                    self?.selectApps(selectedApps ?? [])
                }
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
    
    var currentAppIDs: [String]? {
        defaults.string(forKey: Constants.CURRENT_APPS_KEY)?.components(separatedBy: ",")
    }
    
    func selectApps(_ apps: [AHApp]) {
        defaults.setValue(apps.map { $0.id }.joined(separator: ","), forKey: Constants.CURRENT_APPS_KEY)
        self.currentApps = apps
    }

    func fetchDashboardsFor(appIDs: [String], period: IntentPeriod, fromWidget: Bool, completion: @escaping (Dashboard?) -> Void) {
        
        let dates = Self.datesFromPeriod(period)
        let startTime = dates.0
        let endTime = dates.1

        fetchDashboardsFor(appIDs: appIDs, startTime: startTime, endTime: endTime, fromWidget: fromWidget, completion: completion)
    }
    
    func fetchDashboardsFor(appIDs: [String], startTime: String, endTime: String, fromWidget: Bool, completion: @escaping (Dashboard?) -> Void) {
        self.lastStartTime = startTime
        self.lastEndTime = endTime
        self.isLoading = true
        NetworkService.shared.fetchDashboards(appIds: appIDs, startTime: startTime, endTime: endTime) { dash in
            DispatchQueue.main.async { [weak self] in
                self?.dashboard = dash
                self?.isLoading = false
                if !fromWidget {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                completion(dash)
            }
        }
    }
    
    static func datesFromPeriod(_ period: IntentPeriod) -> (String, String) {
        let startTime: String
        let endTime: String
        let date: Date
        switch period {
        case .today, .unknown:
            date = Date()
            endTime = date.endOfDay.utcString
        case .yesterday:
            date = Date().daysFromNow(-1)
            endTime = date.endOfDay.utcString
        case .last_7_days:
            date = Date().daysFromNow(-7)
            endTime = Date().endOfDay.utcString
        case .last_28_days:
            date = Date().daysFromNow(-28)
            endTime = Date().endOfDay.utcString
        case .last_month:
            date = Date()
            startTime = date.monthsFromNow(-1).startOfMonth.startOfDay.utcString
            endTime = date.monthsFromNow(-1).endOfMonth.startOfDay.utcString
            return (startTime, endTime)
        case .this_month:
            date = Date().startOfMonth.startOfDay
            endTime = Date().endOfDay.utcString
        }
        
        guard let result = Date.getUTCStartEndTime(from: date.timeIntervalSince1970) else {
            return ("", "")
        }
        
        startTime = result.startTime.utcString
        
        return (startTime, endTime)
    }
}
