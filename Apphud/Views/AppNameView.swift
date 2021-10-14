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
            if let app = session.currentApp {
                if let url = session.currentApp?.iconURL {
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
            } else {
                Image(systemName: "rectangle.stack")
            }
            Spacer()
        }
    }
}

struct AppNameView_Previews: PreviewProvider {
    static var previews: some View {
        AppNameView().environmentObject(SessionStore())
    }
}
