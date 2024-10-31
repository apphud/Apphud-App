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

struct DashboardView: View {
    @EnvironmentObject var session: SessionStore
    @State var showingChooseApps = false
    @State private var isRefreshing = false
    @State private var startTime = Date.getUTCStartEndTime(from: Date().timeIntervalSince1970)?.startTime ?? Date()
    @State private var endTime = Date.getUTCStartEndTime(from: Date().timeIntervalSince1970)?.endTime ?? Date()
    @State private var selectedPeriod: IntentPeriod? = .today
    @State private var showingLogoutActionSheet = false
    @Environment(\.colorScheme) var colorScheme
    
    @State private var datesPickerVisible = false
    
    var body: some View {
        NavigationView {
                VStack {
                    if session.currentApps == nil {
                        Text("No app(s) selected")
                    } else {
                        
                        appsTitleView()
                        dateButtonView()
                        
                        if let dash = session.dashboard, !session.isLoading {
                            List {
                                ForEach(dash.groups, id:\.formattedName) { section in
                                    Section(header: HStack {
                                        Text(section.formattedName)
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
                        } else {
                            Text("Loading data, please wait...").frame(maxHeight: .infinity).font(.caption2).opacity(0.7).bold()
                        }
                    }
                }
                .navigationBarTitle("Dashboard".t, displayMode: .inline)
            .navigationBarItems(trailing: Button(action: logoutTapped, label: {
                if let user = session.session, let url = URL(string: user.avatarUrl) {
                    KFImage(url).resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(Circle())
                        .frame(width: 24, height: 24, alignment: .center)
                    
                }
            })).onAppear(perform: session.fetchApps)
        }
        .overlay(content: {
            if (datesPickerVisible) {
                datesPickerView()
            } else {
                EmptyView()
            }
        })
    }

    func setPeriod(_ period: IntentPeriod) {
        
        selectedPeriod = period
        datesPickerVisible.toggle()
        fetchDashboard()
    }
    
    func logoutTapped() {
        self.showingLogoutActionSheet = true
    }

    func chooseAppTapped() {
        self.showingChooseApps.toggle()
    }

    func fetchDashboard() {
        guard let apps = session.currentApps else {return}
        let appIDs = apps.map { $0.id }
        self.isRefreshing = true
        datesPickerVisible = false
        
        if let period = selectedPeriod {
            session.fetchDashboardsFor(appIDs: appIDs, period: period, fromWidget: false) { _ in
                self.isRefreshing = false
            }
        } else {
            session.fetchDashboardsFor(appIDs: appIDs, startTime: startTime.startOfDay.utcString, endTime: endTime.endOfDay.utcString, fromWidget: false) { _ in
                self.isRefreshing = false
            }
        }
    }
    
    @ViewBuilder
    func appsTitleView() -> some View {
        Button(action: chooseAppTapped, label: {
            AppNameView()
                .environmentObject(session)
        }).sheet(isPresented: $showingChooseApps) {
            ChooseAppView(selections: session.currentApps ?? []).environmentObject(session)
        }
        .actionSheet(isPresented: $showingLogoutActionSheet, content: {
            ActionSheet(title: Text("Confirm log out"), message: nil, buttons: [
                .destructive(Text("Log out"), action: {
                    self.session.logout()
                }),
                .cancel()
            ])
        })
        .padding()
    }
    
    func pickerButtonTitle() -> String {
        if let period = selectedPeriod {
            return period.periodTitle()
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd MMM"
            return formatter.string(from: startTime) + " – " + formatter.string(from: endTime)
        }
    }
    
    @ViewBuilder
    func dateButtonView() -> some View {
        VStack {
            Text("Viewing data for").font(.system(size: 10)).opacity(0.5).bold()
            Button(pickerButtonTitle()) {
                datesPickerVisible.toggle()
            }.bold()
        }
    }
    
    @ViewBuilder
    func datesPickerView() -> some View {
        ZStack {
            Color.black.opacity(0.3).onTapGesture {
                datesPickerVisible.toggle()
            }
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 10) {
                        Button(IntentPeriod.today.periodTitle()) { setPeriod(.today) }
                        Button(IntentPeriod.yesterday.periodTitle()) { setPeriod(.yesterday) }
                        Button(IntentPeriod.last_7_days.periodTitle()) { setPeriod(.last_7_days) }
                        Button(IntentPeriod.last_28_days.periodTitle()) { setPeriod(.last_28_days) }
                        Button(IntentPeriod.last_month.periodTitle()) { setPeriod(.last_month) }
                        Button(IntentPeriod.this_month.periodTitle()) { setPeriod(.this_month) }
                    }.font(.callout).bold()
                    datePickerView()
                        .frame(width: 160)
                }
                Button("Apply") {
                    selectedPeriod = nil
                    fetchDashboard()
                }
                .font(.system(size: 16, weight: .heavy))
                .padding(.top, 10)
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 20)
            .background(Color.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }.ignoresSafeArea()
    }
    
    @ViewBuilder
    func datePickerView() -> some View {
        VStack(spacing: 10) {
            DatePicker("", selection: $startTime, in: ...Date(), displayedComponents: .date).onChange(of: startTime, perform: { value in
            })
            .environmentObject(session)
            .foregroundColor((colorScheme == .dark ? Color.blue : Color.black))
                        
            DatePicker("", selection: $endTime, in: ...Date(), displayedComponents: .date).onChange(of: endTime, perform: { value in
            })
            .environmentObject(session)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView().environmentObject(SessionStore.mock())
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
