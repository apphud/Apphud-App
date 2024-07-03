//
//  Widgets.swift
//  Widgets
//
//  Created by Alexander Selivanov on 03.10.2020.
//

import WidgetKit
import SwiftUI
import Intents

let UPDATE_POLICY_TIMER: TimeInterval = 60*30 // 30 minutes

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ApphudWidgetEntry {
        ApphudWidgetEntry(date: Date(), configuration: ConfigurationIntent(), dashboard: Dashboard.mock(), user: User.mock, apps: [AHApp.mock])
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ApphudWidgetEntry) -> ()) {
        let entry = ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: Dashboard.mock(), user: User.mock, apps: [AHApp.mock])
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ApphudWidgetEntry] = []
        let session = SessionStore()

        if let user = AuthService.shared.currentUser {
            if let intentApps = configuration.app {
                let appIds = intentApps.map { $0.identifier ?? "Unknown" }
                
                let apps = AppsManager.shared.findApps(appIds)
                
                let period = configuration.period
                
                session.fetchDashboardsFor(appIDs: appIds.suffix(10), period: period, fromWidget: true) { (dashboard) in
                    guard let dashboard = dashboard else { return }
                    let updateDate = Date().advanced(by: UPDATE_POLICY_TIMER)
                    let entry = ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: dashboard, user: user, apps: apps)
                    entries.append(entry)

                    DispatchQueue.main.async {
                        let timeline = Timeline(entries: entries, policy: .after(updateDate))
                        completion(timeline)
                    }
                }
            }
        } else {
            let timeline = Timeline(entries: [ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: nil, user: nil, apps: [])], policy: .never)
            completion(timeline)
        }
    }
}

struct ApphudWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let dashboard: Dashboard?
    let user: User?
    let apps: [AHApp]
}

struct WidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        if entry.user != nil {
            AppWidgetView(entry: entry)
        } else {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("Please, open app and login first".t)
                        .font(.system(size: 17))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Spacer()
                }
                Spacer()
            }
            .widgetBackground(Color.accentColor)
        }
    }
}

struct ApphudWidget: Widget {
    let kind: String = "Widgets"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Apphud Widget")
        .description("Set up your metrics, like Sales, Proceeds, MRR, etc.")
        .supportedFamilies([.systemSmall])
    }
}

extension View {
    func widgetBackground(_ backgroundView: some View) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(for: .widget) {
                backgroundView
            }
        } else {
            return background(backgroundView)
        }
    }
}

struct AppWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(metricName + " (" + entry.configuration.period.periodTitle().lowercased() + ")")
                    .font(.system(size: 15, weight: .regular, design: .default))
                    .minimumScaleFactor(0.6)
                    .lineLimit(2)
                    .frame(minHeight: 20, alignment: .leading)
                Text("\(metricString)")
                    .bold()
                    .lineLimit(1)
                    .font(.system(size: 20, weight: .semibold, design: .default))
                    .minimumScaleFactor(0.5)
                Spacer()
                Text("Last checked at".t + " ").font(.system(size: 9)) + Text(entry.date, style: .time).font(.system(size: 9))
                Spacer()
                Text("\(appsNames())")
                    .font(.footnote)
                    .lineLimit(2)
                    .minimumScaleFactor(0.4)
            }
            .foregroundColor(.white)
            .font(.footnote)
            Spacer()
        }
        .widgetBackground(Color.accentColor)
    }
    
    func appsNames() -> String {
        if (entry.apps.count == 1) {
            entry.apps.first!.name
        } else if (entry.apps.count == 0) {
            "No apps selected"
        } else {
            entry.apps.first!.name + "\nand " + String(entry.apps.count - 1) + " more"
        }
    }
    
    var metricName: String {
        entry.configuration.metric.toString()
    }
    
    var metricString: String {
        if entry.dashboard == nil {
            return "Error"
        } else {
            return entry.dashboard?.metricValue(intentMetric: entry.configuration.metric) ?? "Unknown Value"
        }
    }
}

@main
struct WidgetsBundle: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
        ApphudWidget()
    }
}

struct ApphudWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        
        let config = ConfigurationIntent()
        config.metric = .proceeds
        
        return AppWidgetView(
            entry: ApphudWidgetEntry(
                date: Date(),
                configuration: config,
                dashboard: Dashboard.mock(),
                user: User.mock,
                apps: [AHApp.mock]
            )
        ).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
