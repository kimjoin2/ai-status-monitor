//
//  MediumWidgetView.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI
import WidgetKit

struct MediumWidgetView: View {
    let entry: AIStatusEntry
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("AI Status Monitor")
                        .font(.subheadline)
                        .fontWeight(.bold)
                    
                    Text("Service Status Overview")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(colorForStatus(entry.overallStatus))
                        .frame(width: 12, height: 12)
                    
                    Text(entry.overallStatus.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 8) {
                ServiceCard(
                    name: "Claude",
                    fullName: "Anthropic",
                    status: entry.claudeStatus
                )
                
                ServiceCard(
                    name: "OpenAI",
                    fullName: "ChatGPT",
                    status: entry.openAIStatus
                )
                
                ServiceCard(
                    name: "Gemini",
                    fullName: "Google AI",
                    status: entry.geminiStatus
                )
            }
            
            HStack {
                Text("Last updated: \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding(12)
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

struct ServiceCard: View {
    let name: String
    let fullName: String
    let status: ServiceStatus
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 16, height: 16)
            
            VStack(spacing: 1) {
                Text(name)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.8)
                
                Text(fullName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.7)
            }
            
            Text(statusText(status))
                .font(.caption2)
                .foregroundColor(colorForStatus(status))
                .fontWeight(.medium)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(6)
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
    
    private func statusText(_ status: ServiceStatus) -> String {
        switch status {
        case .operational:
            return "OK"
        case .degraded:
            return "Issues"
        case .outage:
            return "Down"
        }
    }
}