//
//  APIRouter.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Alamofire
import Foundation
import AnyCodable

enum Router: URLRequestConvertible {

    var baseURL: URL {
        guard let url = URL(string: Constants.BASE_URL) else {
            fatalError()
        }
        return url
    }

    case login(String, String)
    case getApps
    case getNowDashboard([String])
    case getNowMRRDashboard([String])
    case getRangeDashboard([String], String, String)
    case refreshToken
    case logout
    case me
    
    var method: Alamofire.HTTPMethod {
        switch self {
        case .getApps, .me:
            return .get
        case .login(_, _), .refreshToken, .getNowDashboard(_), .getRangeDashboard(_, _, _), .getNowMRRDashboard(_):
            return .post
        case .logout:
            return .delete
        }
    }

    var path: String {
        switch self {
        case .getApps:
            return "apps"
        case .getNowDashboard(_):
            return "api/v1/dash/now"
        case .getNowMRRDashboard(_):
            return "api/v1/dash/now_mrr"
        case .getRangeDashboard(_, _, _):
            return "api/v1/dash/range"
        case .login(_, _):
            return "sessions"
        case .logout:
            return "sessions/logout"
        case .refreshToken:
            return "sessions/refresh"
        case .me:
            return "user"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .refreshToken:
            return ["refresh_token": AuthService.shared.refreshToken]
        case .login(let email, let pass):
            return ["email": email, "password": pass]
        case .getNowDashboard(let appID):
            return ["app": appID]
        case .getNowMRRDashboard(let appID):
            return ["app": appID]
        case .getRangeDashboard(let appID, let startTime, let endTime):
            return ["app": appID,
                    "time_range": ["from": startTime, "to": endTime]
                    ]
        default:
            break
        }

        return nil
    }


    func asURLRequest() throws -> URLRequest {
        var url = baseURL
            .appendingPathComponent(path)

        if method == .get, let params = parameters as? [String: String] {
            url = url.appendingQueryParameters(params)
        }

        var request = URLRequest(url: url)
        request.method = method
        request.setValue(Locale.current.languageCode!, forHTTPHeaderField: "x-locale")
        request.setValue("iOS-APP", forHTTPHeaderField: "x-client")

        if method == .post {
            do {
                if let params = parameters  {
                    return try JSONParameterEncoder.default.encode(AnyEncodable(params), into: request)
                }
            } catch {
                print(error.localizedDescription)
            }
        }

        return request
    }
}

extension URL {
    func appendingQueryParameters(_ parameters: [String: String]) -> URL {
        let queryItems = parameters.keys.map { URLQueryItem(name: $0, value: parameters[$0]) }
        guard var urlComps = URLComponents(string: absoluteString) else {
            return self
        }
        urlComps.queryItems = queryItems
        guard let finalURL = urlComps.url else {
            return self
        }
        return finalURL
    }
}
