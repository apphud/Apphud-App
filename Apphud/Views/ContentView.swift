//
//  ContentView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var session: SessionStore
    
    var body: some View {
        Group {
            if session.loading {
                LoaderView()
            } else {
                if session.logged {
                    DashboardView().environmentObject(session)
                } else {
                    WelcomeView().environmentObject(session)
                }
            }
        }.onAppear(perform: session.listen)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(SessionStore())
    }
}
