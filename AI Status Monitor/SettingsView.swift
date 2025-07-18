//
//  SettingsView.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var notificationSettings = NotificationSettings.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // 타이틀 바
            HStack {
                Text("Notification Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            .background(Color(NSColor.windowBackgroundColor))
            
            // 메인 콘텐츠
            ScrollView {
                VStack(spacing: 30) {
                    // Service Notifications Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Service Notifications")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 15) {
                            HStack {
                                Text("Claude Notifications")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.claudeNotificationsEnabled)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("OpenAI Notifications")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.openAINotificationsEnabled)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                Text("Gemini Notifications")
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.geminiNotificationsEnabled)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                    
                    // Notification Types Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Notification Types")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 15) {
                            HStack {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                        .foregroundColor(.red)
                                        .frame(width: 24)
                                    Text("Service Outage")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.notifyOnOutage)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.yellow)
                                        .frame(width: 24)
                                    Text("Performance Degradation")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.notifyOnDegraded)
                                    .labelsHidden()
                            }
                            
                            HStack {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                        .frame(width: 24)
                                    Text("Service Recovery")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Toggle("", isOn: $notificationSettings.notifyOnRecovery)
                                    .labelsHidden()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                    
                    // Notification Guide Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Notification Guide")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .foregroundColor(.red)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Service Outage")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Service is completely unavailable")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.yellow)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Performance Degradation")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Service is slow or has partial issues")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            
                            HStack {
                                Image(systemName: "checkmark.circle")
                                    .foregroundColor(.green)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Service Recovery")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text("Issues resolved and service is back to normal")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
            }
        }
        .frame(minWidth: 500, minHeight: 600)
    }
}

#Preview {
    SettingsView()
}