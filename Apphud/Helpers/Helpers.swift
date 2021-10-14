//
//  Helpers.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import Foundation

func Log(_ text: Any) {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss,SSS"
    let time = formatter.string(from: Date())
    print("[\(time)] [AppLog] \(text)")
}
