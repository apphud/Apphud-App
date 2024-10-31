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

    func fetchDashboard(appIds: [String], startTime: String, endTime: String) async -> Dashboard? {
        
        Log("Fetch Dashboard For AppIds: \(appIds), startTime: \(startTime), endTime: \(endTime)")

        async let dashRange: Dashboard? = fetchRangeDashboard(appIds: appIds, startTime: startTime, endTime: endTime)
        async let dashNow: Dashboard? = fetchNowDashboard(appIds: appIds)
        async let dashMRR: Dashboard? = fetchMRRDashboard(appIds: appIds)
        
        if await dashRange != nil, await dashMRR != nil, await dashNow != nil {
            
            let mixedDash = Dashboard.merge(first: await dashNow!, second: await dashRange!)
            let finalDash = Dashboard.merge(first: await dashMRR!, second: mixedDash)
            return finalDash
        } else {
            return nil
        }
    }
    
    private func fetchRangeDashboard(appIds: [String], startTime: String, endTime: String) async -> Dashboard? {
        await withUnsafeContinuation { continuation in
            session.request(Router.getRangeDashboard(appIds, startTime, endTime)).validate().responseDecodable(of: Dashboard.self, decoder: decoder) { response in
                self.prettyLog(data: response.data, request: response.request)
                if let value = response.value {
                    continuation.resume(returning: value)
                } else if let error = response.error {
                    Log("WebAPI error = \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    private func fetchNowDashboard(appIds: [String]) async -> Dashboard? {
        await withUnsafeContinuation { continuation in
            session.request(Router.getNowDashboard(appIds)).validate().responseDecodable(of: Dashboard.self, decoder: decoder) { response in
                self.prettyLog(data: response.data, request: response.request)

                if let value = response.value {
                    continuation.resume(returning: value)
                } else if let error = response.error {
                    Log("WebAPI error = \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
        
    }
    
    private func fetchMRRDashboard(appIds: [String]) async -> Dashboard? {
        await withUnsafeContinuation { continuation in
            session.request(Router.getNowMRRDashboard(appIds)).validate().responseDecodable(of: Dashboard.self, decoder: decoder) { response in
                self.prettyLog(data: response.data, request: response.request)

                if let value = response.value {
                    continuation.resume(returning: value)
                } else if let error = response.error {
                    Log("WebAPI error = \(error)")
                    continuation.resume(returning: nil)
                }
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
        
//        return
        
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

