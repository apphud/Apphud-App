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

    @State var selections: [AHApp]
    
    @State var allSelected = false
    
    @State var showsError = false
    
    var body: some View {
        NavigationView{
            VStack {
                Group {
                    List(session.apps, id: \.id) { app in
                        AppItemView(app: app, isSelected: self.selections.contains(app))
                            .contentShape(Rectangle())
                            .onTapGesture(count: 1, perform: {
                                if self.selections.contains(app) {
                                    self.selections.removeAll(where: { $0 == app })
                                } else if self.selections.count < 10 {
                                    self.selections.append(app)
                                } else {
                                    showsError.toggle()
                                }
                        })
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .onAppear(perform: session.fetchApps)
            .navigationBarTitle("Choose App(s)".t)
            .toolbar(content: {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(allSelected ? "Deselect All" : "Select All") {
                        if allSelected {
                            self.selections = []
                            self.allSelected = false
                        } else {
                            if session.apps.count > 10 {
                                showsError.toggle()
                            } else {
                                self.selections = session.apps
                                self.allSelected = true
                            }
                        }
                    }
                }
                            ToolbarItem(placement: .navigationBarTrailing) {
                                Button("Apply") {
                                    if self.selections.count > 10 {
                                        showsError.toggle()
                                    } else {
                                        session.selectApps(self.selections)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }
                        })
        }
        .alert(isPresented: $showsError, content: {
            Alert(title: Text("Too many apps").bold(), message: Text("You can select up to 10 apps"), dismissButton: .default(Text("OK")))
        })
    }
}



struct ChooseAppView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseAppView(selections: []).environmentObject(SessionStore.mock())
    }
}
