//
//  AIStatusEntry.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import Foundation
import WidgetKit

struct AIStatusEntry: TimelineEntry {
    let date: Date
    let claudeStatus: ServiceStatus
    let openAIStatus: ServiceStatus
    let geminiStatus: ServiceStatus
    
    var isAllOperational: Bool {
        return claudeStatus == .operational && 
               openAIStatus == .operational && 
               geminiStatus == .operational
    }
    
    var hasOutage: Bool {
        return claudeStatus == .outage || 
               openAIStatus == .outage || 
               geminiStatus == .outage
    }
    
    var hasDegraded: Bool {
        return claudeStatus == .degraded || 
               openAIStatus == .degraded || 
               geminiStatus == .degraded
    }
    
    var overallStatus: ServiceStatus {
        if hasOutage {
            return .outage
        } else if hasDegraded {
            return .degraded
        } else {
            return .operational
        }
    }
}