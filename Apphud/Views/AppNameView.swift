//
//  AppNameView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI
import struct Kingfisher.KFImage

struct AppNameView: View {
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        HStack {
            if session.currentApps?.count == 1, let app = session.currentApps?.first {
                if let url = app.iconURL {
                    Group {
                        KFImage(url).resizable()
                            .background(Color(hex: "F5F5F5"))
                                    .aspectRatio(contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }.frame(width: 24, height: 24)
                }
                Text(app.name)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
            } else if session.currentApps?.count ?? 0 == session.apps.count && session.apps.count > 4 {
                
                Text("All Apps (\(session.apps.count))")
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(1)
                
            } else if session.currentApps?.count ?? 0 > 1 {
                Text( prepareMiltiAppsTitle())
                    .multilineTextAlignment(.leading)
                    .lineLimit(10)
            } else {
                Image(systemName: "rectangle.stack")
            }
            Spacer()
        }
    }
    
    func prepareMiltiAppsTitle() -> String {
        let names = session.currentApps!.map { $0.name }
        var namesString = names.joined(separator: ", ")
        
        if let range = namesString.range(of: ", ", options: .backwards) {
            namesString = namesString.replacingCharacters(in: range, with: " and ")
        }
        
        return  String(names.count) + " Apps: " + namesString
    }
}

struct AppNameView_Previews: PreviewProvider {
    static var previews: some View {
        Button(action: {}, label: {
            AppNameView().environmentObject(SessionStore.mock())
                .multilineTextAlignment(.leading)
        })
    }
        
}
