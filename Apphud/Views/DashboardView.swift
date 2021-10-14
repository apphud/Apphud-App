//
//  ContentView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import SwiftUI
import struct Kingfisher.KFImage
import SwiftUIRefresh
import WidgetKit
import TTProgressHUD

struct DashboardView: View {
    @EnvironmentObject var session: SessionStore
    @State var showingChooseApps = false
    @State private var isRefreshing = false
    @State private var startTime: Date = Date().daysFromNow(-1).startOfDay
    @State private var endTime = Date().endOfDay
    @State private var selectedPeriod: IntentPeriod = .today
    @State private var showingLogoutActionSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    if session.currentApp == nil {
                        Text("No app selected")
                    } else {
                        
                        if let dash = session.dashboard {
                            
                            datePickerView()
                            
                            List {
                                ForEach(dash.groups, id:\.uniqueName) { section in
                                    Section(header: HStack {
                                        Text(section.uniqueName)
                                            .font(.system(size: 17, weight: .regular, design: .default))
                                            .foregroundColor((Color(hex: "97ADC6")))
                                            .padding()
                                            .autocapitalization(.sentences)
                                        
                                        Spacer()
                                    }
                                    .textCase(nil)
                                    .autocapitalization(.sentences)
                                    .background(colorScheme == .dark ? Color.black : Color(hex:"F8FBFF"))
                                    .listRowInsets(EdgeInsets(
                                                    top: 0,
                                                    leading: 5,
                                                    bottom: 0,
                                                    trailing: 0))
                                    )
                                    {
                                        ForEach(section.items, id:\.name) { metric in
                                            DashboardMetricView(metric: metric)
                                                
                                        }
                                    }
                                }
                            }
                            .listStyle(PlainListStyle()).listSeparatorStyle()
                            .pullToRefresh(isShowing: $isRefreshing) {
                                fetchDashboard()
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Dashboard".t)
            .navigationBarItems(leading: Button(action: chooseAppTapped, label: {
                AppNameView()
                    .environmentObject(session)
                    .frame(maxWidth:280)
            }).sheet(isPresented: $showingChooseApps) {
                ChooseAppView().environmentObject(session)
            }
            .actionSheet(isPresented: $showingLogoutActionSheet, content: {
                ActionSheet(title: Text("Confirm log out"), message: nil, buttons: [
                    .destructive(Text("Log out"), action: {
                        self.session.logout()
                    }),
                    .cancel()
                ])
            })
            .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)), trailing: Button(action: logoutTapped, label: {
                if let user = session.session, let url = URL(string: user.avatarUrl) {
                    KFImage(url).resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .frame(width: 24, height: 24, alignment: .center)
                    
                }
            })).onAppear(perform: session.fetchApps)
        }
    }

    func logoutTapped() {
        self.showingLogoutActionSheet = true
    }

    func chooseAppTapped() {
        self.showingChooseApps.toggle()
    }

    func fetchDashboard() {
        guard let appID = session.currentApp?.id else {return}
        self.isRefreshing = true
        
        session.fetchDashboardFor(appID: appID, startTime: startTime.startOfDay.utcString, endTime: endTime.endOfDay.utcString, fromWidget: false) { _ in
            self.isRefreshing = false
        }
    }
    
    @ViewBuilder
    func datePickerView() -> some View {
        HStack {
            DatePicker("", selection: $startTime, in: ...Date(), displayedComponents: .date).onChange(of: startTime, perform: { value in
                            fetchDashboard()
                            
                        })
            .environmentObject(session)
//              .frame(maxWidth: .infinity)
            
            Text(" – ")
                .foregroundColor((colorScheme == .dark ? Color.blue : Color.black)).frame(maxWidth: .infinity)
            DatePicker("", selection: $endTime, in: ...Date(), displayedComponents: .date).onChange(of: endTime, perform: { value in
                            fetchDashboard()
                        })
            .environmentObject(session)
//              .frame(maxWidth: .infinity)
        }.padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView().environmentObject(SessionStore())
    }
}

public struct ListSeparatorStyleModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content.onAppear {
            UITableViewHeaderFooterView.appearance().tintColor = .clear
            UITableView.appearance().backgroundColor = .clear // tableview background
            UITableViewCell.appearance().backgroundColor = .clear
            UITableViewHeaderFooterView.appearance().backgroundView = .init()
            UITableView.appearance().layoutMargins = UIEdgeInsets.zero
        }
    }
}

extension View {
    public func listSeparatorStyle() -> some View {
        modifier(ListSeparatorStyleModifier())
    }
}
