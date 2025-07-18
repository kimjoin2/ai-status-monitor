//
//  SmallWidgetView.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI
import WidgetKit

struct SmallWidgetView: View {
    let entry: AIStatusEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("AI Status")
                    .font(.headline)
                    .fontWeight(.bold)
                    .minimumScaleFactor(0.8)
                
                Spacer()
                
                Circle()
                    .fill(colorForStatus(entry.overallStatus))
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                StatusRowSmall(service: "Claude", status: entry.claudeStatus)
                StatusRowSmall(service: "OpenAI", status: entry.openAIStatus)
                StatusRowSmall(service: "Gemini", status: entry.geminiStatus)
            }
            
            Spacer()
            
            Text(entry.date, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .containerBackground(for: .widget) { }
    }
    
    private func colorForStatus(_ status: ServiceStatus) -> Color {
        switch status {
        case .operational:
            return .green
        case .degraded:
            return .orange
        case .outage:
            return .red
        }
    }
}

struct StatusRowSmall: View {
    let service: String
    let status: ServiceStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 6, height: 6)
            
            Text(service)
                .font(.caption)
                .minimumScaleFactor(0.7)
            
            Spacer()
        }
    }
    
    private func colorForStatus(_ status: ServiceStatus) -> Color {
        switch status {
        case .operational:
            return .green
        case .degraded:
            return .orange
        case .outage:
            return .red
        }
    }
}