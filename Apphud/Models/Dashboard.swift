//
//  Dashboard.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import Foundation

class Dashboard: Codable {
    
    var groups: [DashboardMetricGroup]
        
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        groups = try values.decode([DashboardMetricGroup].self, forKey: .groups)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(groups, forKey: .groups)
    }
    
    func metricValue(intentMetric: IntentMetric) -> String? {
        var value: String? = nil
        groups.forEach { g in
            g.items.forEach { metric in
                if metric.name.lowercased() == intentMetric.toString().lowercased() && value == nil {
                    value = metric.valueNumber
                }
            }
        }
        return value
    }
    
    private enum CodingKeys: String, CodingKey {
        case groups
    }
    
    init(groups: [DashboardMetricGroup]) {
        self.groups = groups
    }
    
    static var mock: Dashboard {
        
        Dashboard(groups: [
            DashboardMetricGroup(name: "MRR", items: [
                DashboardMetric(name: "Monthly Recurring Revenue", type: "money", values: [DashboardValue(name: "Value", value: 145)], description: "MRR is monthly recurring revenue")
            ]),
            DashboardMetricGroup(name: "Money", items: [
                DashboardMetric(name: "Proceeds", type: "money", chart_id: "proceeds", values: [DashboardValue(name: "Value", value: 123.45)], description: "Proceeds")
            ])
        ])
    }
    
    static func merge(first: Dashboard, second: Dashboard) -> Dashboard {
        let merged = first.groups + second.groups
        return Dashboard(groups: merged)
    }
}

struct DashboardMetricGroup: Codable {
    var uniqueName: String {
        if items.count == 1 {
            return items.first!.name
        } else {
            return name
        }
    }
    let name: String
    let items: [DashboardMetric]
}

struct DashboardMetric: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case name, values, type, description, chart_id
    }
    
    var name: String
    var type: String
    var chart_id: String?
    var values: [DashboardValue]
    var description: String
    var isMoney: Bool { type == "money" }
    var value: Double { values.first(where: { $0.name == "Value" })?.value ?? 0 }
    var activeValue: Int? {
        let active = values.first(where: { $0.name == "Active" })?.value
        return active != nil ? Int(active!) : nil
    }
    var inactiveValue: Int? {
        let inactive = values.first(where: { $0.name == "Inactive" })?.value
        return inactive != nil ? Int(inactive!) : nil
    }
    
    var valueNumber: String { isMoney ? value.formattedAmount() : value.humanNumber() }
}

struct DashboardValue: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case name, value
    }
    
    var name: String
    var value: Double
}
