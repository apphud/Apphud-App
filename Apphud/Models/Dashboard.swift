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
        
    static func merge(first: Dashboard, second: Dashboard) -> Dashboard {
        let merged = first.groups + second.groups
        return Dashboard(groups: merged)
    }
    
    func find(name: String) -> DashboardMetric? {
        for group in groups {
            for metric in group.items {
                if metric.name == name {
                    return metric
                }
            }
        }
        return nil
    }
    
    static func combineMultiDashboard(first: Dashboard, second: Dashboard) -> Dashboard {
        
        var newGroups = [DashboardMetricGroup]()
        
        for group in first.groups {
            var newMetrics = [DashboardMetric]()
            
            for metric in group.items {
                
                let secondMetric = second.find(name: metric.name)
                    
                var newValues = [DashboardValue]()
                
                for value in metric.values ?? [] {
                    let secondValue = secondMetric?.find(name: value.name)
                    let newValue = DashboardValue(name: value.name, value: value.value + (secondValue?.value ?? 0))
                    newValues.append(newValue)
                }
                
                if metric.chart_id == "refund_rate" || metric.chart_id == "arpu" || metric.chart_id == "arppu" {
                    // cannot combine these cohort metrics
                } else {
                    let newMetric = DashboardMetric(name: metric.name, type: metric.type, values: newValues, description: metric.description)
                    
                    newMetrics.append(newMetric)
                }
                
            }
            
            newGroups.append(DashboardMetricGroup(name: group.name, items: newMetrics))
        }
        
        return Dashboard(groups: newGroups)
    }
    
    static func mock() -> Dashboard {
        let group1 = DashboardMetricGroup(name: "MRR", items: [.mockMRR()])
        let group2 = DashboardMetricGroup(name: "Money", items: [.mockSales(), .mockSales(), .mockSales()])
        let group3 = DashboardMetricGroup(name: "Subscriptions", items: [.mockActiveRegulars(), .mockActiveRegulars(), .mockActiveRegulars()])
        let group4 = DashboardMetricGroup(name: "Users", items: [.mockNewUsers()])
        
        return .init(groups: [group1, group2, group3, group4])
    }
}

struct DashboardMetricGroup: Codable {
    var formattedName: String {
        if name == "Money" && (["mrr", "arr", "Monthly Recurring Revenue", "MRR", "ARR", "Annual Recurring Revenue"].contains(items.first?.name)) {
            return "Recurring Revenue"
        } else {
            return name
        }
    }
    fileprivate let name: String
    let items: [DashboardMetric]
}

struct DashboardMetric: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case name, values, type, description, chart_id
    }
    
    var name: String
    var type: String
    var chart_id: String?
    var values: [DashboardValue]?
    var description: String
    var isMoney: Bool { type == "money" }
    var value: Double { values?.first(where: { $0.name == "Value" })?.value ?? 0 }
    var activeValue: Int? {
        let active = values?.first(where: { $0.name == "Active" })?.value
        return active != nil ? Int(active!) : nil
    }
    var inactiveValue: Int? {
        let inactive = values?.first(where: { $0.name == "Inactive" })?.value
        return inactive != nil ? Int(inactive!) : nil
    }
    
    func find(name: String) -> DashboardValue? {
        for v in values ?? [] {
            if v.name == name {
                return v
            }
        }
        
        return nil
    }
    
    var valueNumber: String { isMoney ? value.formattedAmount() : value.humanNumber() }
    
    static func mockSales() -> DashboardMetric {
        DashboardMetric(name: "Sales", type: "money", chart_id: "sales", values: [.init(name: "Value", value: 495.34)], description: "Total amount billed to customers for purchasing in-app purchases. Sales = Gross Revenue - Refunds.")
    }
    
    static func mockNewUsers() -> DashboardMetric {
        DashboardMetric(name: "New Users", type: "simple", chart_id: "new_users", values: [.init(name: "Value", value: 1356)], description: "Number of new users within selected period.")
    }
    
    static func mockMRR() -> DashboardMetric {
        DashboardMetric(name: "MRR", type: "money", chart_id: "mrr", values: [.init(name: "Value", value: 12977)], description: "MRR is recurring proceeds revenue normalized in to a monthly amount.")
    }
    
    static func mockActiveRegulars() -> DashboardMetric {
        DashboardMetric(name: "Active Regular Subscriptions", type: "subscriptions", chart_id: "", values: [.init(name: "Value", value: 500), .init(name: "Active", value: 200), .init(name: "Inactive", value: 300)], description: "Number of currently active regular subscriptions.")
    }
}

struct DashboardValue: Codable {
    
    private enum CodingKeys: String, CodingKey {
        case name, value
    }
    
    var name: String
    var value: Double
}
