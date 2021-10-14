//
//  Widgets.swift
//  Widgets
//
//  Created by Alexander Selivanov on 03.10.2020.
//

import WidgetKit
import SwiftUI
import Intents

let UPDATE_POLICY_TIMER: TimeInterval = 60*10 // 10 minutes

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> ApphudWidgetEntry {
        ApphudWidgetEntry(date: Date(), configuration: ConfigurationIntent(), dashboard: Dashboard.mock, user: User.mock, app: AHApp.mock)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (ApphudWidgetEntry) -> ()) {
        let entry = ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: Dashboard.mock, user: User.mock, app: AHApp.mock)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [ApphudWidgetEntry] = []
        let session = SessionStore()

        if let user = AuthService.shared.currentUser {
            if let appId = configuration.app?.identifier,
               let app = AppsManager.shared.findApp(appId) {
                let period = configuration.period
                
                session.fetchDashboardFor(appID: appId, period: period, fromWidget: true) { (dashboard) in
                    guard let dashboard = dashboard else { return }
                    let updateDate = Date().advanced(by: UPDATE_POLICY_TIMER)
                    let entry = ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: dashboard, user: user, app: app)
                    entries.append(entry)

                    DispatchQueue.main.async {
                        let timeline = Timeline(entries: entries, policy: .after(updateDate))
                        completion(timeline)
                    }
                }
            }
        } else {
            let timeline = Timeline(entries: [ApphudWidgetEntry(date: Date(), configuration: configuration, dashboard: nil, user: nil, app: nil)], policy: .never)
            completion(timeline)
        }
    }
}

struct ApphudWidgetEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let dashboard: Dashboard?
    let user: User?
    let app: AHApp?
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
                        .font(.body)
                        .padding()
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                    Spacer()
                }
                Spacer()
            }
            .background(Color.accentColor)
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

struct AppWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Spacer()
                Text(metricName)
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .minimumScaleFactor(0.6)
                    .frame(minHeight: 20, alignment: .leading)
                Text("\(metricString)")
                    .bold()
                    .lineLimit(1)
                    .font(.system(size: 27, weight: .semibold, design: .default))
                    .minimumScaleFactor(0.5)
                Spacer()
                Text("Last checked at".t)
                Text(entry.date, style: .time)
                Spacer()
                Text("\(entry.app!.name)")
                    .font(.footnote)
                    .padding(.bottom, 4)
                Spacer()
            }
            .font(.footnote)
            .padding()
            Spacer()
        }
        .background(Color.accentColor)
        .foregroundColor(.white)
    }
    
    var metricName: String {
        entry.configuration.metric.toString()
    }
    
    var metricString: String {
        if entry.dashboard == nil {
            return "Couldn't fetch dashboard"
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

struct ApphudWidget_Previews: PreviewProvider {
    static var previews: some View {
        
        let config = ConfigurationIntent()
        config.metric = .proceeds
        
        return WidgetEntryView(
            entry: ApphudWidgetEntry(
                date: Date(),
                configuration: config,
                dashboard: Dashboard.mock,
                user: User.mock,
                app: AHApp.mock
            )
        ).previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
