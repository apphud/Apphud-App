//
//  ChooseAppView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct ChooseAppView: View {
    @EnvironmentObject var session: SessionStore
    @Environment(\.presentationMode) var presentationMode

    @State private var selection: Int? = 2
    
    var body: some View {
        NavigationView{
            Group {
                List(session.apps, selection: $selection) { app in
                    AppItemView(app: app)
                        .contentShape(Rectangle())
                        .onTapGesture(count: 1, perform: {
                        session.selectApp(app)
                        self.presentationMode.wrappedValue.dismiss()
                    })
                }.padding()
            }.onAppear(perform: session.fetchApps)
            .navigationBarTitle("Choose App".t)
        }
    }
}

struct ChooseAppView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseAppView().environmentObject(SessionStore())
    }
}
