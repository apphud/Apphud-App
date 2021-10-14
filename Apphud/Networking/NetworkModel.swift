//
//  NetworkModel.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation
import Alamofire

final class RequestInterceptor: Alamofire.RequestInterceptor {
    init() {}

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        guard urlRequest.url?.absoluteString.hasPrefix(Constants.BASE_URL) == true else {
            /// If the request does not require authentication, we can directly return it as unmodified.
            return completion(.success(urlRequest))
        }
        var urlRequest = urlRequest

        /// Set the Authorization header value using the access token.
        urlRequest.setValue("Bearer " + AuthService.shared.accessToken, forHTTPHeaderField: "Authorization")

        completion(.success(urlRequest))
    }

    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse, response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.

            return completion(.doNotRetryWithError(error))
        }

        NetworkService.shared.refreshToken { token in
            guard let token = token else {
                completion(.doNotRetryWithError(error))
                return
            }

            AuthService.shared.saveTokens(token)
            completion(.retry)
        }
    }
}
