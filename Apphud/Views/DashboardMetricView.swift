//
//  DashboardMetricView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct DashboardMetricView: View {
    var metric: DashboardMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7, content: {
            Text(metric.name).font(.system(size: 17, weight: .regular, design: .default))
            
            HStack(alignment: .center) {
                Text("\(metric.valueNumber)") .font(.system(size: 30, weight: .bold, design: .default))
                
                Spacer()
                if let inactive = metric.inactiveValue, let active = metric.activeValue {
                    HStack(alignment: .center) {
                        HStack(alignment: .center) {
                            Image("enabled-count-icon").frame(width: 16, height: 16, alignment: .center)
                            Text("\(active)").foregroundColor(Color("green"))
                        }
                        
                        HStack(alignment: .center) {
                            Image("disabled-count-icon").frame(width: 16, height: 16, alignment: .center)
                            Text("\(inactive)").foregroundColor(Color("red"))
                        }
                    }
                }
            }
        })
    }
}

struct DashboardMetricView_Previews: PreviewProvider {
    static var previews: some View {
        Text("Hello, World!")
    }
}
