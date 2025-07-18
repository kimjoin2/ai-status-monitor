//
//  NotificationSettings.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import Foundation
import UserNotifications

class NotificationSettings: ObservableObject {
    @Published var claudeNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(claudeNotificationsEnabled, forKey: "claudeNotificationsEnabled")
        }
    }
    
    @Published var openAINotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(openAINotificationsEnabled, forKey: "openAINotificationsEnabled")
        }
    }
    
    @Published var geminiNotificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(geminiNotificationsEnabled, forKey: "geminiNotificationsEnabled")
        }
    }
    
    @Published var notifyOnDegraded: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnDegraded, forKey: "notifyOnDegraded")
        }
    }
    
    @Published var notifyOnOutage: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnOutage, forKey: "notifyOnOutage")
        }
    }
    
    @Published var notifyOnRecovery: Bool {
        didSet {
            UserDefaults.standard.set(notifyOnRecovery, forKey: "notifyOnRecovery")
        }
    }
    
    static let shared = NotificationSettings()
    
    private init() {
        // UserDefaults에서 설정 불러오기 (기본값: true)
        self.claudeNotificationsEnabled = UserDefaults.standard.object(forKey: "claudeNotificationsEnabled") as? Bool ?? true
        self.openAINotificationsEnabled = UserDefaults.standard.object(forKey: "openAINotificationsEnabled") as? Bool ?? true
        self.geminiNotificationsEnabled = UserDefaults.standard.object(forKey: "geminiNotificationsEnabled") as? Bool ?? true
        self.notifyOnDegraded = UserDefaults.standard.object(forKey: "notifyOnDegraded") as? Bool ?? true
        self.notifyOnOutage = UserDefaults.standard.object(forKey: "notifyOnOutage") as? Bool ?? true
        self.notifyOnRecovery = UserDefaults.standard.object(forKey: "notifyOnRecovery") as? Bool ?? true
    }
    
    func shouldNotify(for service: String, from oldStatus: ServiceStatus, to newStatus: ServiceStatus) -> Bool {
        // 서비스별 알림 설정 확인
        let serviceEnabled = switch service {
        case "Claude": claudeNotificationsEnabled
        case "OpenAI": openAINotificationsEnabled
        case "Gemini": geminiNotificationsEnabled
        default: false
        }
        
        if !serviceEnabled {
            return false
        }
        
        // 중요도별 알림 설정 확인
        switch (oldStatus, newStatus) {
        case (.operational, .degraded), (.outage, .degraded):
            return notifyOnDegraded
        case (.operational, .outage), (.degraded, .outage):
            return notifyOnOutage
        case (.degraded, .operational), (.outage, .operational):
            return notifyOnRecovery
        default:
            return false
        }
    }
    
    func getNotificationSound(for newStatus: ServiceStatus) -> UNNotificationSound {
        switch newStatus {
        case .outage:
            return .default  // 장애 시 기본 소리
        case .degraded:
            return .default  // 성능 저하 시 기본 소리 (macOS에서는 defaultCritical 사용 불가)
        case .operational:
            return .default  // 복구 시 기본 소리
        }
    }
    
    func getNotificationTitle(for service: String, status: ServiceStatus) -> String {
        switch status {
        case .outage:
            return "🚨 \(service) Service Outage"
        case .degraded:
            return "⚠️ \(service) Performance Issues"
        case .operational:
            return "✅ \(service) Service Restored"
        }
    }
}