//
//  AIStatusWidget.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI
import WidgetKit

struct AIStatusWidget: Widget {
    let kind: String = "AIStatusWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AIStatusProvider()) { entry in
            AIStatusWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AI Status Monitor")
        .description("Monitor the status of AI services")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct AIStatusWidgetEntryView: View {
    var entry: AIStatusEntry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

#Preview(as: .systemSmall) {
    AIStatusWidget()
} timeline: {
    AIStatusEntry(date: Date(), claudeStatus: .operational, openAIStatus: .operational, geminiStatus: .operational)
    AIStatusEntry(date: Date(), claudeStatus: .degraded, openAIStatus: .operational, geminiStatus: .outage)
}

#Preview(as: .systemMedium) {
    AIStatusWidget()
} timeline: {
    AIStatusEntry(date: Date(), claudeStatus: .operational, openAIStatus: .operational, geminiStatus: .operational)
    AIStatusEntry(date: Date(), claudeStatus: .degraded, openAIStatus: .operational, geminiStatus: .outage)
}

#Preview(as: .systemLarge) {
    AIStatusWidget()
} timeline: {
    AIStatusEntry(date: Date(), claudeStatus: .operational, openAIStatus: .operational, geminiStatus: .operational)
    AIStatusEntry(date: Date(), claudeStatus: .degraded, openAIStatus: .operational, geminiStatus: .outage)
}