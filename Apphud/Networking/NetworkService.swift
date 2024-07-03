//
//  NetworkService.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import UIKit
import Alamofire

private struct WebAPIResponse<T: Decodable>: Decodable {
    var data: T
    var errors: [WebAPIError]?
}

private struct WebAPIError: Decodable {
    var id: String
    var title: String
}

private struct WebAPIArrayResult<T: Decodable>: Decodable {
    var results: [T]?
}

private struct WebAPIObjectWithMetaResult<T: Decodable, W: Decodable>: Decodable {
    var results: T?
    var meta: W?
}

private struct WebAPIObjectResult<T: Decodable>: Decodable {
    var results: T?
}

class NetworkService {
    static let shared = NetworkService()
    private let decoder = JSONDecoder()
    private var session: Session
    private var sessionConfig: URLSessionConfiguration
    private var interceptor: RequestInterceptor
    private init() {
        sessionConfig = URLSessionConfiguration.af.default
        sessionConfig.httpMaximumConnectionsPerHost = 3
        interceptor = RequestInterceptor()

        session = Session(configuration: sessionConfig, interceptor: interceptor)
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted(DateFormatter.iso8601Full)
    }
    
    func login(email: String, password: String, callback: @escaping (User?, TokenPair?) -> Void) {
        postAction(Router.login(email, password), callback: callback)
    }
    
    func me(_ callback: @escaping (User?, TokenPair?) -> Void) {
        requestObject(Router.me, callback: callback)
    }

    func refreshToken(_ callback: @escaping (TokenPair?) -> Void) {
        
        typealias ObjectResponse = WebAPIResponse<WebAPIObjectResult<TokenPair>>
        
        session.request(Router.refreshToken).responseDecodable(of: ObjectResponse.self, decoder: decoder) { response in

            self.prettyLog(data: response.data, request: response.request)

            if let error = response.error {
                Log("WebAPI error = \(error)")
                callback(nil)
            } else if let value = response.value {
                callback(value.data.results)
            }
        }
    }
    
    func fetchApps(_ callback: @escaping ([AHApp]?) -> Void) {
        requestArray(Router.getApps, callback: callback)
    }

    func fetchDashboards(appIds: [String], startTime: String, endTime: String, callback: @escaping (Dashboard?) -> Void) {
        Task {
            let dash = await fetchMultiDashboard(appIds: appIds, startTime: startTime, endTime: endTime)
            Task { @MainActor in
                callback(dash)
            }
        }
    }

    func fetchMultiDashboard(appIds: [String], startTime: String, endTime: String) async -> Dashboard? {
        await withTaskGroup(of: (Dashboard?, String).self) { taskGroup in
            var dashboards: [(Dashboard, String)] = []
            
            for appId in appIds {
                taskGroup.addTask {
                    await self.fetchDashboard(appId: appId, startTime: startTime, endTime: endTime)
                }
            }
            
            for await dashboardTuple in taskGroup {
                if let dashboard = dashboardTuple.0 {
                    dashboards.append((dashboard, dashboardTuple.1))
                }
            }
            
            if dashboards.count != appIds.count {
                return nil
            }
            
            if let firstDash = dashboards.first {
                var newDash = firstDash.0
                let firstAppId = firstDash.1
                
                for dashTuple in dashboards {
                    if (dashTuple.1 != firstAppId) {
                        newDash = Dashboard.combineMultiDashboard(first: newDash, second: dashTuple.0)
                    }
                }
                
                return newDash
            }
            
            return nil
        }
    }

    func fetchDashboard(appId: String, startTime: String, endTime: String) async -> (Dashboard?, String) {
        // Simulate network call
        return await withCheckedContinuation { continuation in
            fetchDashboard(appId: appId, startTime: startTime, endTime: endTime) { dashboard in
                continuation.resume(returning: (dashboard, appId))
            }
        }
    }
    
    func fetchDashboard(appId: String, startTime: String, endTime: String, callback: @escaping (Dashboard?) -> Void) {
        
        Log("Fetch Dashboard: \(appId), startTime: \(startTime), endTime: \(endTime)")
        
        var dashRangeLoaded = false
        var dashNowLoaded = false
        var dashRange: Dashboard? = nil
        var dashNow: Dashboard? = nil
        
        let finalBlock: ((Dashboard?, Dashboard?) -> Void) = { d1, d2 in
            if d1 != nil && d2 != nil {
                callback(Dashboard.merge(first: d1!, second: d2!))
            } else {
                callback(d1 ?? d2)
            }
        }
        
        fetchRangeDashboard(appId: appId, startTime: startTime, endTime: endTime) { dash in
            dashRange = dash
            dashRangeLoaded = true
            Log("Fetched Range Dashboard: \(appId), startTime: \(startTime), endTime: \(endTime)")
            if dashNowLoaded {
                finalBlock(dashNow, dashRange)
            }
        }
        
        fetchNowDashboard(appId: appId) { dash in
            dashNow = dash
            dashNowLoaded = true
            Log("Fetched Now Dashboard: \(appId), startTime: \(startTime), endTime: \(endTime)")
            if dashRangeLoaded {
                finalBlock(dashNow, dashRange)
            }
        }
    }
    
    private func fetchRangeDashboard(appId: String, startTime: String, endTime: String, callback: @escaping (Dashboard?) -> Void) {
        
        session.request(Router.getRangeDashboard(appId, startTime, endTime)).validate().responseDecodable(of: Dashboard.self, decoder: decoder) { response in
            self.prettyLog(data: response.data, request: response.request)

            if let value = response.value {
                callback(value)
            } else if let error = response.error {
                Log("WebAPI error = \(error)")
                callback(nil)
            }
        }
    }
    
    private func fetchNowDashboard(appId: String, callback: @escaping (Dashboard?) -> Void) {
        session.request(Router.getNowDashboard(appId)).validate().responseDecodable(of: Dashboard.self, decoder: decoder) { response in
            self.prettyLog(data: response.data, request: response.request)

            if let value = response.value {
                callback(value)
            } else if let error = response.error {
                Log("WebAPI error = \(error)")
                callback(nil)
            }
        }
    }
    
    private func postAction<T: Decodable, W: Decodable>(_ request: URLRequestConvertible, callback: @escaping (T?, W?) -> Void) {
        typealias ObjectResponse = WebAPIResponse<WebAPIObjectWithMetaResult<T, W>>
        session.request(request).responseDecodable(of: ObjectResponse.self, decoder: decoder) { response in

            self.prettyLog(data: response.data, request: response.request)

            if let error = response.error {
                Log("WebAPI error = \(error)")
                callback(nil, nil)
            } else if let value = response.value {
                callback(value.data.results, value.data.meta)
            }
        }
    }

    private func requestArray<T: Decodable>(_ request: URLRequestConvertible, callback: @escaping ([T]?) -> Void) {
        typealias ArrayResponse = WebAPIResponse<WebAPIArrayResult<T>>

        session.request(request).validate().responseDecodable(of: ArrayResponse.self, decoder: decoder) { response in

            self.prettyLog(data: response.data, request: response.request)

            if let value = response.value {
                callback(value.data.results)
            } else if let error = response.error {
                Log("WebAPI error = \(error)")
                callback(nil)
            }
        }
    }

    private func requestObject<T: Decodable, W: Decodable>(_ request: URLRequestConvertible, callback: ((T?, W?) -> Void)?) {
        typealias ObjectResponse = WebAPIResponse<WebAPIObjectWithMetaResult<T, W>>

        session.request(request).validate().responseDecodable(of: ObjectResponse.self, decoder: decoder) { response in
            self.prettyLog(data: response.data, request: response.request)

            if let value = response.value {
                callback?(value.data.results, value.data.meta)
            } else if let error = response.error {
                Log("WebAPI error = \(error)")
                callback?(nil, nil)
            }
        }
    }

    func prettyLog(data: Data?, request: URLRequest?) {
        
        return
        
        do {
            if let data = data, let urlString = request?.url?.absoluteString, let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] {
                let json = try JSONSerialization.data(withJSONObject: dictionary, options: .prettyPrinted)
                if let string = String(data: json, encoding: .utf8) {
                    Log("API REQUEST SUCCESS (\(urlString)) RESPONSE:\n\(string)")
                }
            }
        } catch {
            Log("API REQUEST FAILED: \(String(describing: request?.url)) HEADERS: \(String(describing: request?.allHTTPHeaderFields)), EXCEPTION: \n\(error.localizedDescription)")
        }
    }
}

