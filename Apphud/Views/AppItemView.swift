//
//  AppItemView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI
import struct Kingfisher.KFImage

struct AppItemView: View {
    @EnvironmentObject var session: SessionStore
    var app: AHApp
    var body: some View {
        HStack {
            Group {
                if let url = app.iconURL {
                    KFImage(url).resizable()
                                .background(Color(hex: "F5F5F5"))
                                .aspectRatio(contentMode: .fit)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                } else {
                    Image("app_icon_placeholder").resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(8)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }.frame(width: 44, height: 44)
            Text(app.name).frame(maxWidth: .infinity, alignment: .leading)
            if app.id == session.currentApp?.id {
                Image("select_app_image")
            }
        }
    }
}

struct AppItemView_Previews: PreviewProvider {
    static var previews: some View {
        AppItemView(app: AHApp(id: "", name: "Diff", bundleId: "com", packageName: nil, iconUrl: "http://placehold.it/199"))
    }
}
