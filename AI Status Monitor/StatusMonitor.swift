//
//  StatusMonitor.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import SwiftUI
import Foundation
import UserNotifications
import WidgetKit

class StatusMonitor: ObservableObject {
    @Published var claudeStatus: ServiceStatus = .operational
    @Published var openAIStatus: ServiceStatus = .operational
    @Published var geminiStatus: ServiceStatus = .operational
    @Published var lastUpdate: Date?
    
    private var timer: Timer?
    private var previousStatuses: [String: ServiceStatus] = [:]
    
    init() {
        requestNotificationPermission()
    }
    
    func startMonitoring() {
        refreshStatus()
        
        // 위젯 즉시 업데이트
        WidgetCenter.shared.reloadAllTimelines()
        
        timer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { _ in
            self.refreshStatus()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    func refreshStatus() {
        Task {
            await fetchAllStatuses()
        }
    }
    
    @MainActor
    func fetchAllStatuses() async {
        let group = DispatchGroup()
        var newClaudeStatus: ServiceStatus = .operational
        var newOpenAIStatus: ServiceStatus = .operational
        var newGeminiStatus: ServiceStatus = .operational
        
        group.enter()
        Task {
            let items = await RSSFeedParser.fetchAnthropicStatus()
            newClaudeStatus = getClaudeStatus(from: items)
            group.leave()
        }
        
        group.enter()
        Task {
            if let status = await OpenAIStatusParser.fetchOpenAIStatus() {
                newOpenAIStatus = OpenAIStatusParser.getOverallStatus(from: status)
            }
            group.leave()
        }
        
        group.enter()
        Task {
            if let status = await GoogleCloudStatusParser.fetchGoogleCloudStatus() {
                newGeminiStatus = GoogleCloudStatusParser.getOverallStatus(from: status)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            self.updateStatuses(
                claude: newClaudeStatus,
                openAI: newOpenAIStatus,
                gemini: newGeminiStatus
            )
        }
    }
    
    private func updateStatuses(claude: ServiceStatus, openAI: ServiceStatus, gemini: ServiceStatus) {
        let oldStatuses = ["Claude": claudeStatus, "OpenAI": openAIStatus, "Gemini": geminiStatus]
        
        claudeStatus = claude
        openAIStatus = openAI
        geminiStatus = gemini
        lastUpdate = Date()
        
        let newStatuses = ["Claude": claude, "OpenAI": openAI, "Gemini": gemini]
        
        for (service, newStatus) in newStatuses {
            if let oldStatus = oldStatuses[service], oldStatus != newStatus {
                sendStatusChangeNotification(service: service, from: oldStatus, to: newStatus)
            }
        }
        
        previousStatuses = newStatuses
        
        // 위젯 업데이트 요청
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    private func getClaudeStatus(from items: [ServiceStatusItem]) -> ServiceStatus {
        let ongoingKeywords = ["investigating", "monitoring", "identified", "partial", "degraded", "outage"]
        let resolvedKeywords = ["resolved", "fixed", "completed", "restored"]
        
        let ongoingIssue = items.first { item in
            let titleLower = item.title.lowercased()
            let descLower = item.description.lowercased()
            
            let hasOngoingKeyword = ongoingKeywords.contains { keyword in
                titleLower.contains(keyword) || descLower.contains(keyword)
            }
            
            let hasResolvedKeyword = resolvedKeywords.contains { keyword in
                titleLower.contains(keyword) || descLower.contains(keyword)
            }
            
            return hasOngoingKeyword && !hasResolvedKeyword
        }
        
        if let issue = ongoingIssue {
            if issue.title.lowercased().contains("outage") || issue.description.lowercased().contains("outage") {
                return .outage
            }
            return .degraded
        }
        
        return .operational
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    private func sendStatusChangeNotification(service: String, from oldStatus: ServiceStatus, to newStatus: ServiceStatus) {
        let content = UNMutableNotificationContent()
        content.title = "AI Service Status Change"
        content.body = "\(service) status changed from \(oldStatus.description) to \(newStatus.description)"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "status-change-\(service)-\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification error: \(error)")
            }
        }
    }
}

extension RSSFeedParser {
    static func fetchAnthropicStatus() async -> [ServiceStatusItem] {
        guard let url = URL(string: "https://status.anthropic.com/history.rss") else {
            return []
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let parser = RSSFeedParser()
            return parser.parse(data: data)
        } catch {
            print("Error fetching Anthropic status: \(error)")
            return []
        }
    }
}

class OpenAIStatusParser {
    static func fetchOpenAIStatus() async -> OpenAIStatus? {
        guard let url = URL(string: "https://status.openai.com/api/v2/summary.json") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            return try decoder.decode(OpenAIStatus.self, from: data)
        } catch {
            print("Error fetching OpenAI status: \(error)")
            return nil
        }
    }
    
    static func getOverallStatus(from status: OpenAIStatus) -> ServiceStatus {
        switch status.status.indicator {
        case "none":
            return .operational
        case "minor":
            return .degraded
        case "major":
            return .outage
        default:
            return .operational
        }
    }
    
    static func hasActiveIncidents(from status: OpenAIStatus) -> Bool {
        return !(status.incidents?.isEmpty ?? true)
    }
}

class GoogleCloudStatusParser {
    static let vertexGeminiProductID = "Z0FZJAMvEB4j3NbCJs6B"
    
    static func fetchGoogleCloudStatus() async -> GoogleCloudStatus? {
        guard let url = URL(string: "https://status.cloud.google.com/incidents.json") else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoder = JSONDecoder()
            
            // Try to decode as array first, then fall back to object
            let allIncidents: [GoogleCloudStatus.GoogleCloudIncident]
            if let incidentsArray = try? decoder.decode([GoogleCloudStatus.GoogleCloudIncident].self, from: data) {
                allIncidents = incidentsArray
            } else {
                // Handle case where API returns different format
                print("Google Cloud API returned unexpected format, using empty incidents list")
                allIncidents = []
            }
            
            let geminiIncidents = allIncidents.filter { incident in
                incident.affected_products?.contains { product in
                    product.id == vertexGeminiProductID
                } ?? false
            }
            
            return GoogleCloudStatus(incidents: geminiIncidents)
        } catch {
            print("Error fetching Google Cloud status: \(error)")
            return GoogleCloudStatus(incidents: [])
        }
    }
    
    static func getOverallStatus(from status: GoogleCloudStatus) -> ServiceStatus {
        let activeIncidents = status.incidents.filter { incident in
            incident.end == nil || incident.end?.isEmpty == true
        }
        
        if activeIncidents.isEmpty {
            return .operational
        }
        
        let hasMajorIncident = activeIncidents.contains { incident in
            let severity = incident.severity?.lowercased() ?? ""
            let statusImpact = incident.status_impact?.lowercased() ?? ""
            return severity.contains("high") || 
                   severity.contains("critical") ||
                   statusImpact.contains("service_disruption") ||
                   statusImpact.contains("service_outage")
        }
        
        return hasMajorIncident ? .outage : .degraded
    }
    
    static func hasActiveIncidents(from status: GoogleCloudStatus) -> Bool {
        return status.incidents.contains { incident in
            incident.end == nil || incident.end?.isEmpty == true
        }
    }
    
    static func getLatestIncident(from status: GoogleCloudStatus) -> GoogleCloudStatus.GoogleCloudIncident? {
        let activeIncidents = status.incidents.filter { incident in
            incident.end == nil || incident.end?.isEmpty == true
        }
        
        if activeIncidents.isEmpty {
            return status.incidents.first
        }
        
        return activeIncidents.first
    }
}

extension StatusMonitor {
    static let shared = StatusMonitor()
}