//
//  Constants.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

struct Constants {
    static let BASE_URL = "https://api.apphud.com"
    static let JWT_TOKEN_KEY = "JWT_TOKEN_KEY"
    static let REFRESH_TOKEN_KEY = "REFRESH_TOKEN_KEY"
    static let CURRENT_USER_KEY = "CURRENT_USER_KEY"
    static let CURRENT_APP_KEY = "CURRENT_APP_KEY"
    static let APPS_LIST_KEY = "APPS_LIST_KEY"
    static let APP_GROUP_ID = "group.apphud.dashboard"
    static let TEAM_ID = "JLG6CF288G"
    static let keyChainGroup = "com.apphud"
    static let keyChainGroupID = "\(TEAM_ID).\(keyChainGroup)"
}

extension IntentPeriod {
    func periodTitle() -> String {
        switch self {
        case .today:
            return "today".t
        case .yesterday:
            return "yesterday".t
        case .week:
            return "a week".t
        case .four_weeks:
            return "a month".t
        case .three_months:
            return "3 Months".t
        case .year:
            return "year".t
        case .lifetime:
            return "lifetime".t
        default:
            return "Unknown"
        }
    }
}

extension IntentMetric {
    func toString() -> String {
        // should match name from API
        switch self {
        case .arppu:
            return "ARPPU"
        case .arpu:
            return "ARPU"
        case .grossRevenue:
            return "Gross Revenue"
        case .mrr:
            return "Monthly Recurring Revenue"
        case .proceeds:
            return "Proceeds"
        case .refunds:
            return "Refunds"
        case .sales:
            return "Sales"
        case .trials:
            return "New Trials"
        case .regulars:
            return "New Regular Subscriptions"
        default:
            return "Unknown"
        }
    }
}
