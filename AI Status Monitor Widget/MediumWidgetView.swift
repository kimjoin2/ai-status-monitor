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
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status Monitor")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Service Status Overview")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Circle()
                        .fill(colorForStatus(entry.overallStatus))
                        .frame(width: 16, height: 16)
                    
                    Text(entry.overallStatus.description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(spacing: 16) {
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
            
            Spacer()
            
            HStack {
                Text("Last updated: \(entry.date, style: .time)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
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

struct ServiceCard: View {
    let name: String
    let fullName: String
    let status: ServiceStatus
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 20, height: 20)
            
            VStack(spacing: 2) {
                Text(name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .minimumScaleFactor(0.8)
                
                Text(fullName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .minimumScaleFactor(0.8)
            }
            
            Text(statusText(status))
                .font(.caption2)
                .foregroundColor(colorForStatus(status))
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
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