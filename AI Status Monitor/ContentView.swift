//
//  ContentView.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var statusMonitor = StatusMonitor()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Status Monitor")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("Monitor the status of AI services")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 16) {
                ServiceStatusCard(
                    serviceName: "Claude (Anthropic)",
                    status: statusMonitor.claudeStatus,
                    lastUpdate: statusMonitor.lastUpdate,
                    onTap: {
                        if let url = URL(string: "https://status.anthropic.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
                
                ServiceStatusCard(
                    serviceName: "ChatGPT (OpenAI)",
                    status: statusMonitor.openAIStatus,
                    lastUpdate: statusMonitor.lastUpdate,
                    onTap: {
                        if let url = URL(string: "https://status.openai.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
                
                ServiceStatusCard(
                    serviceName: "Gemini (Google Cloud)",
                    status: statusMonitor.geminiStatus,
                    lastUpdate: statusMonitor.lastUpdate,
                    onTap: {
                        if let url = URL(string: "https://status.cloud.google.com") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            VStack(spacing: 8) {
                Button("Refresh Status") {
                    statusMonitor.refreshStatus()
                }
                .buttonStyle(.borderedProminent)
                
                if let lastUpdate = statusMonitor.lastUpdate {
                    Text("Last updated: \(lastUpdate, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom)
        }
        .padding()
        .frame(minWidth: 180, minHeight: 500)
        .onAppear {
            statusMonitor.startMonitoring()
        }
        .onDisappear {
            statusMonitor.stopMonitoring()
        }
    }
}

struct ServiceStatusCard: View {
    let serviceName: String
    let status: ServiceStatus
    let lastUpdate: Date?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(serviceName)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        Circle()
                            .fill(colorForStatus(status))
                            .frame(width: 12, height: 12)
                        
                        Text(status.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.up.right.square")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separatorColor), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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


#Preview {
    ContentView()
}
