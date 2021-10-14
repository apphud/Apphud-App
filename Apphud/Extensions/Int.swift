//
//  Int.swift
//  Apphud
//
//  Created by Alexander Selivanov on 06.10.2020.
//

import Foundation

extension Int {
    func formattedAmount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale =  Locale(identifier: "en_US")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "" // "$123.44"
    }
    func humanNumber() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "" // "$123.44"
    }
}

extension Double {
    func formattedAmount() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale =  Locale(identifier: "en_US")
        return formatter.string(from: NSNumber(value: self)) ?? "" // "$123.44"
    }
    
    func humanNumber() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: self)) ?? "" // "$123.44"
    }
}
