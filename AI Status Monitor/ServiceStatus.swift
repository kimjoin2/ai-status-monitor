//
//  ServiceStatus.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import Foundation

enum ServiceStatus: Codable, Equatable {
    case operational
    case degraded  
    case outage
    
    var description: String {
        switch self {
        case .operational:
            return "Operational"
        case .degraded:
            return "Degraded Performance"
        case .outage:
            return "Major Outage"
        }
    }
    
    var color: String {
        switch self {
        case .operational:
            return "green"
        case .degraded:
            return "orange"
        case .outage:
            return "red"
        }
    }
}

struct ServiceStatusItem: Codable {
    let title: String
    let description: String
    let pubDate: Date
    let link: String
}

struct OpenAIStatus: Codable {
    let status: StatusIndicator
    let incidents: [OpenAIIncident]?
    
    struct StatusIndicator: Codable {
        let indicator: String
    }
    
    struct OpenAIIncident: Codable {
        let id: String
        let name: String
        let status: String
        let created_at: String
        let updated_at: String
        let shortlink: String
    }
}

struct GoogleCloudStatus: Codable {
    let incidents: [GoogleCloudIncident]
    
    struct GoogleCloudIncident: Codable {
        let id: String
        let number: String?
        let begin: String
        let end: String?
        let severity: String?
        let status_impact: String?
        let external_desc: String?
        let updates: [IncidentUpdate]?
        let affected_products: [AffectedProduct]?
        
        struct IncidentUpdate: Codable {
            let created: String
            let text: String
            let status: String?
        }
        
        struct AffectedProduct: Codable {
            let id: String
            let title: String?
        }
    }
}