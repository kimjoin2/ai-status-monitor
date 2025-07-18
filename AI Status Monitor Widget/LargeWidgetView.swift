//
//  LargeWidgetView.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI
import WidgetKit

struct LargeWidgetView: View {
    let entry: AIStatusEntry
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("AI Status Monitor")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Real-time service status monitoring")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Circle()
                        .fill(colorForStatus(entry.overallStatus))
                        .frame(width: 24, height: 24)
                    
                    Text(entry.overallStatus.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Status Overview
            HStack(spacing: 12) {
                StatusIndicator(
                    title: "Operational",
                    count: operationalCount,
                    color: .green
                )
                
                StatusIndicator(
                    title: "Issues",
                    count: degradedCount,
                    color: .orange
                )
                
                StatusIndicator(
                    title: "Outages",
                    count: outageCount,
                    color: .red
                )
            }
            
            // Detailed Service Status
            VStack(spacing: 8) {
                DetailedServiceRow(
                    serviceName: "Claude (Anthropic)",
                    status: entry.claudeStatus,
                    description: "AI Assistant Platform"
                )
                
                DetailedServiceRow(
                    serviceName: "ChatGPT (OpenAI)",
                    status: entry.openAIStatus,
                    description: "Conversational AI Service"
                )
                
                DetailedServiceRow(
                    serviceName: "Gemini (Google AI)",
                    status: entry.geminiStatus,
                    description: "Multimodal AI Platform"
                )
            }
            
            Spacer()
            
            // Footer
            HStack {
                Text("Last updated: \(entry.date, formatter: dateFormatter)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Updates every 15 minutes")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) { }
    }
    
    private var operationalCount: Int {
        [entry.claudeStatus, entry.openAIStatus, entry.geminiStatus]
            .filter { $0 == .operational }
            .count
    }
    
    private var degradedCount: Int {
        [entry.claudeStatus, entry.openAIStatus, entry.geminiStatus]
            .filter { $0 == .degraded }
            .count
    }
    
    private var outageCount: Int {
        [entry.claudeStatus, entry.openAIStatus, entry.geminiStatus]
            .filter { $0 == .outage }
            .count
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
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

struct StatusIndicator: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct DetailedServiceRow: View {
    let serviceName: String
    let status: ServiceStatus
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(colorForStatus(status))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(serviceName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(status.description)
                .font(.caption)
                .foregroundColor(colorForStatus(status))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(colorForStatus(status).opacity(0.1))
                .cornerRadius(4)
        }
        .padding(.vertical, 4)
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