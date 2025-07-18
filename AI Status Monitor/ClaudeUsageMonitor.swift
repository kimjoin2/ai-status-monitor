//
//  ClaudeUsageMonitor.swift
//  AI Status Monitor
//
//  Created by BUMNYEONG on 2025/07/18.
//

import Foundation
import SwiftUI

struct ClaudeUsageData: Codable {
    let timestamp: String
    let message: Message?
    let costUSD: Double?
    let version: String?
    let type: String?
    
    struct Message: Codable {
        let model: String?
        let usage: Usage?
        
        struct Usage: Codable {
            let input_tokens: Int?
            let output_tokens: Int?
            let cache_creation_input_tokens: Int?
            let cache_read_input_tokens: Int?
        }
    }
}

struct SessionBlock {
    let startTime: Date
    let endTime: Date
    let tokenCounts: TokenCounts
    let costUSD: Double
    let models: [String]
    let isActive: Bool
    
    struct TokenCounts {
        let inputTokens: Int
        let outputTokens: Int
        let cacheCreationTokens: Int
        let cacheReadTokens: Int
        
        var totalTokens: Int {
            return inputTokens + outputTokens + cacheCreationTokens + cacheReadTokens
        }
    }
}

struct BurnRate {
    let tokensPerMinute: Double
    let costPerHour: Double
}

class ClaudeUsageMonitor: ObservableObject {
    @Published var currentSession: SessionBlock?
    @Published var burnRate: BurnRate?
    @Published var sessionProgress: Double = 0.0
    @Published var tokenUsagePercent: Double = 0.0
    @Published var projectedCost: Double = 0.0
    @Published var projectedTokens: Int = 0
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private let sessionDurationHours: Double = 5.0
    private let tokenLimit: Int = 500000 // Default token limit
    
    // Block reset configuration - based on Tokyo time 2025-07-18 12:00
    // Reference block start: July 18, 2025 12:00 PM JST
    private let referenceBlockStart: Date = {
        var components = DateComponents()
        components.year = 2025
        components.month = 7
        components.day = 18
        components.hour = 12
        components.minute = 0
        components.second = 0
        components.timeZone = TimeZone(identifier: "Asia/Tokyo")
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    // Caching for performance optimization
    private var lastScanTime: Date = Date.distantPast
    private var cachedEntries: [ClaudeUsageData] = []
    private var fileModificationDates: [String: Date] = [:]
    
    private func parseTimestamp(_ timestamp: String) -> Date? {
        // Try multiple date formats
        let formatters: [(DateFormatter) -> Void] = [
            { formatter in
                // Format with milliseconds: 2025-07-10T06:30:44.577Z
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
            },
            { formatter in
                // ISO8601 with milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            },
            { formatter in
                // ISO8601 without milliseconds
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
            },
            { formatter in
                // Basic ISO8601
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            }
        ]
        
        for setupFormatter in formatters {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "UTC")
            setupFormatter(formatter)
            
            if let date = formatter.date(from: timestamp) {
                return date
            }
        }
        
        return nil
    }
    
    // Calculate the start time of the block that contains the given date
    // Based on the reference block start time (2025-07-18 12:00 JST)
    private func getBlockStartTime(for date: Date) -> Date {
        let sessionDurationSeconds = sessionDurationHours * 3600
        
        // Calculate how many seconds have passed since the reference block start
        let timeSinceReference = date.timeIntervalSince(referenceBlockStart)
        
        // Find which block this date belongs to
        let blockIndex = floor(timeSinceReference / sessionDurationSeconds)
        
        // Calculate the start time of this block
        let blockStartTime = referenceBlockStart.addingTimeInterval(blockIndex * sessionDurationSeconds)
        
        return blockStartTime
    }
    
    
    private let claudeDataPaths: [URL] = {
        // Try to get actual user home directory, not sandboxed container
        let actualHomeDir: String
        if let homeEnv = ProcessInfo.processInfo.environment["HOME"] {
            actualHomeDir = homeEnv
        } else {
            actualHomeDir = NSHomeDirectory()
        }
        
        let homeDir = URL(fileURLWithPath: actualHomeDir)
        print("🏠 Using home directory: \(actualHomeDir)")
        
        return [
            homeDir.appendingPathComponent(".config/claude/projects"),
            homeDir.appendingPathComponent(".claude/projects")
        ]
    }()
    
    func startMonitoring() {
        isMonitoring = true
        refreshUsageData()
        timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.refreshUsageData()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    private func refreshUsageData() {
        Task {
            await loadCurrentSession()
        }
    }
    
    @MainActor
    private func loadCurrentSession() async {
        print("🚀 loadCurrentSession started")
        do {
            let usageEntries = try await loadUsageEntries()
            print("📝 loadUsageEntries returned \(usageEntries.count) entries")
            let sessionBlocks = createSessionBlocks(from: usageEntries)
            print("📦 createSessionBlocks returned \(sessionBlocks.count) blocks")
            
            // Debug: Print only active blocks
            let activeBlocks = sessionBlocks.filter { $0.isActive }
            if !activeBlocks.isEmpty {
                for (index, block) in activeBlocks.enumerated() {
                    print("   Active Block \(index + 1): \(block.tokenCounts.totalTokens) tokens, $\(block.costUSD)")
                }
            }
            
            if let activeBlock = sessionBlocks.first(where: { $0.isActive }) {
                print("✅ Found active session with \(activeBlock.tokenCounts.totalTokens) tokens")
                currentSession = activeBlock
                calculateMetrics(for: activeBlock)
            } else {
                print("❌ No active session found from \(sessionBlocks.count) blocks")
                currentSession = nil
                burnRate = nil
                sessionProgress = 0.0
                tokenUsagePercent = 0.0
                projectedCost = 0.0
                projectedTokens = 0
            }
        } catch {
            print("❌ Error loading Claude usage data: \(error)")
        }
    }
    
    private func loadUsageEntries() async throws -> [ClaudeUsageData] {
        let now = Date()
        
        // If last scan was less than 10 seconds ago, return cached data
        if now.timeIntervalSince(lastScanTime) < 10.0 && !cachedEntries.isEmpty {
            print("💾 Using cached data (\(cachedEntries.count) entries)")
            return cachedEntries
        }
        
        var allEntries: [ClaudeUsageData] = []
        var hasChanges = false
        
        print("🔍 Scanning for file changes...")
        
        for dataPath in claudeDataPaths {
            guard FileManager.default.fileExists(atPath: dataPath.path) else { 
                continue 
            }
            
            let enumerator = FileManager.default.enumerator(at: dataPath, includingPropertiesForKeys: [.contentModificationDateKey])
            
            while let fileURL = enumerator?.nextObject() as? URL {
                if fileURL.pathExtension == "jsonl" {
                    let filePath = fileURL.path
                    
                    // Check file modification date
                    let attributes = try FileManager.default.attributesOfItem(atPath: filePath)
                    let modificationDate = attributes[.modificationDate] as? Date ?? Date.distantPast
                    
                    let cachedModDate = fileModificationDates[filePath] ?? Date.distantPast
                    
                    if modificationDate > cachedModDate {
                        print("📄 Loading updated file: \(fileURL.lastPathComponent)")
                        let entries = try await loadJSONLFile(at: fileURL)
                        allEntries.append(contentsOf: entries)
                        fileModificationDates[filePath] = modificationDate
                        hasChanges = true
                    }
                }
            }
        }
        
        // If no changes, return cached data
        if !hasChanges && !cachedEntries.isEmpty {
            print("💾 No file changes, using cached data (\(cachedEntries.count) entries)")
            return cachedEntries
        }
        
        // If there were changes, reload all data
        if hasChanges {
            allEntries = []
            for dataPath in claudeDataPaths {
                guard FileManager.default.fileExists(atPath: dataPath.path) else { continue }
                
                let enumerator = FileManager.default.enumerator(at: dataPath, includingPropertiesForKeys: nil)
                while let fileURL = enumerator?.nextObject() as? URL {
                    if fileURL.pathExtension == "jsonl" {
                        let entries = try await loadJSONLFile(at: fileURL)
                        allEntries.append(contentsOf: entries)
                    }
                }
            }
        }
        
        print("🎯 Total entries loaded: \(allEntries.count)")
        
        func parseTimestamp(_ timestamp: String) -> Date? {
            // Try multiple date formats
            let formatters: [(DateFormatter) -> Void] = [
                { formatter in
                    // Format with milliseconds: 2025-07-10T06:30:44.577Z
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
                },
                { formatter in
                    // ISO8601 with milliseconds
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                },
                { formatter in
                    // ISO8601 without milliseconds
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                },
                { formatter in
                    // Basic ISO8601
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                }
            ]
            
            for setupFormatter in formatters {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                setupFormatter(formatter)
                
                if let date = formatter.date(from: timestamp) {
                    return date
                }
            }
            
            return nil
        }
        
        let sortedEntries = allEntries.sorted { 
            parseTimestamp($0.timestamp) ?? Date.distantPast < 
            parseTimestamp($1.timestamp) ?? Date.distantPast 
        }
        
        // Minimal logging for performance
        if sortedEntries.count > 0 {
            print("📅 Data range: \(sortedEntries.first?.timestamp ?? "unknown") to \(sortedEntries.last?.timestamp ?? "unknown")")
        }
        
        // Update cache
        cachedEntries = sortedEntries
        lastScanTime = now
        
        return sortedEntries
    }
    
    private func loadJSONLFile(at url: URL) async throws -> [ClaudeUsageData] {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var entries: [ClaudeUsageData] = []
        let maxEntriesPerFile = 100 // Drastically reduce to prevent crashes
        
        // Process lines in reverse order to get most recent entries first
        for line in lines.suffix(maxEntriesPerFile).reversed() {
            if let data = line.data(using: .utf8) {
                do {
                    let entry = try JSONDecoder().decode(ClaudeUsageData.self, from: data)
                    
                    // Only include assistant messages with usage data
                    if entry.type == "assistant", 
                       let message = entry.message,
                       let usage = message.usage {
                        entries.append(entry)
                    }
                } catch {
                    // Skip malformed lines
                    continue
                }
            }
        }
        
        return entries.reversed() // Return in chronological order
    }
    
    private func createSessionBlocks(from entries: [ClaudeUsageData]) -> [SessionBlock] {
        print("🔍 createSessionBlocks called with \(entries.count) entries")
        guard !entries.isEmpty else { 
            print("⚠️ No entries to create session blocks from")
            return [] 
        }
        
        var blocks: [SessionBlock] = []
        let now = Date()
        
        // Group entries into 5-hour blocks        
        let sortedEntries = entries.sorted { 
            parseTimestamp($0.timestamp) ?? Date.distantPast < 
            parseTimestamp($1.timestamp) ?? Date.distantPast 
        }
        
        // Filter entries with valid timestamps
        let validEntries = sortedEntries.filter { entry in
            parseTimestamp(entry.timestamp) != nil
        }
        
        print("📊 Entries with valid timestamps: \(validEntries.count) out of \(sortedEntries.count)")
        
        guard let firstEntry = validEntries.first,
              let firstTimestamp = parseTimestamp(firstEntry.timestamp) else {
            print("⚠️ Could not get first timestamp from entries (no valid timestamps found)")
            return []
        }
        
        guard let lastEntry = validEntries.last,
              let lastTimestamp = parseTimestamp(lastEntry.timestamp) else {
            print("⚠️ Could not get last timestamp from entries")
            return []
        }
        
        print("📅 Entry time range: \(firstTimestamp) to \(lastTimestamp)")
        print("🕐 Current time: \(now)")
        print("⏱️ Time since last entry: \(now.timeIntervalSince(lastTimestamp)) seconds")
        
        let sessionDurationSeconds = sessionDurationHours * 3600
        
        // Check if data is too old
        let timeSinceLastEntry = now.timeIntervalSince(lastTimestamp)
        let testSessionDurationSeconds: TimeInterval = 7 * 24 * 3600
        if timeSinceLastEntry > testSessionDurationSeconds {
            print("⚠️ Last entry is \(timeSinceLastEntry/3600) hours old, no active session possible")
            return []
        }
        
        // Get the earliest block start time that could contain our data
        let earliestBlockStart = getBlockStartTime(for: firstTimestamp)
        let latestBlockStart = getBlockStartTime(for: lastTimestamp)
        
        print("🔍 Session duration: \(sessionDurationSeconds) seconds (\(sessionDurationHours) hours)")
        print("🔍 Reference block start: \(referenceBlockStart) (2025-07-18 12:00 JST)")
        print("🔍 Earliest block start: \(earliestBlockStart)")
        print("🔍 Latest block start: \(latestBlockStart)")
        
        // Generate all blocks that could contain our data
        var blockStartTime = earliestBlockStart
        while blockStartTime <= now {
            let blockEndTime = blockStartTime.addingTimeInterval(sessionDurationSeconds)
            let blockEntries = validEntries.filter { entry in
                guard let timestamp = parseTimestamp(entry.timestamp) else { return false }
                return timestamp >= blockStartTime && timestamp < blockEndTime
            }
            
            // Consider a block active if it contains recent entries (within 5 hours)
            // For testing, consider any block with entries as potentially active
            let isActive = !blockEntries.isEmpty && (now >= blockStartTime && now < blockEndTime)
            
            // Reduced logging for performance
            
            if !blockEntries.isEmpty {
                let block = createSessionBlock(
                    startTime: blockStartTime,
                    endTime: blockEndTime,
                    entries: blockEntries,
                    isActive: isActive
                )
                blocks.append(block)
                
                if isActive {
                    print("✅ Active block: \(block.tokenCounts.totalTokens) tokens")
                }
            }
            
            blockStartTime = blockEndTime
        }
        
        print("🎯 Total blocks created: \(blocks.count)")
        print("🔥 Active blocks: \(blocks.filter { $0.isActive }.count)")
        
        // If no blocks are active but we have blocks, mark the most recent one as active for testing
        if !blocks.isEmpty && blocks.filter({ $0.isActive }).isEmpty {
            print("🧪 No active blocks found, marking most recent block as active for testing")
            if let lastBlock = blocks.last {
                let activeBlock = SessionBlock(
                    startTime: lastBlock.startTime,
                    endTime: lastBlock.endTime,
                    tokenCounts: lastBlock.tokenCounts,
                    costUSD: lastBlock.costUSD,
                    models: lastBlock.models,
                    isActive: true
                )
                blocks[blocks.count - 1] = activeBlock
            }
        }
        
        return blocks
    }
    
    private func createSessionBlock(startTime: Date, endTime: Date, entries: [ClaudeUsageData], isActive: Bool) -> SessionBlock {
        var inputTokens = 0
        var outputTokens = 0
        var cacheCreationTokens = 0
        var cacheReadTokens = 0
        var totalCost = 0.0
        var models: Set<String> = []
        
        for entry in entries {
            guard let message = entry.message, let usage = message.usage else { continue }
            
            inputTokens += usage.input_tokens ?? 0
            outputTokens += usage.output_tokens ?? 0
            cacheCreationTokens += usage.cache_creation_input_tokens ?? 0
            cacheReadTokens += usage.cache_read_input_tokens ?? 0
            totalCost += entry.costUSD ?? 0.0
            
            if let model = message.model {
                models.insert(model)
            }
        }
        
        let tokenCounts = SessionBlock.TokenCounts(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheCreationTokens: cacheCreationTokens,
            cacheReadTokens: cacheReadTokens
        )
        
        return SessionBlock(
            startTime: startTime,
            endTime: endTime,
            tokenCounts: tokenCounts,
            costUSD: totalCost,
            models: Array(models),
            isActive: isActive
        )
    }
    
    private func calculateMetrics(for block: SessionBlock) {
        let now = Date()
        let sessionDurationSeconds = sessionDurationHours * 3600
        
        // Session progress
        let elapsed = now.timeIntervalSince(block.startTime)
        sessionProgress = min(elapsed / sessionDurationSeconds, 1.0)
        
        // Token usage percentage
        tokenUsagePercent = Double(block.tokenCounts.totalTokens) / Double(tokenLimit)
        
        // Calculate burn rate (tokens per minute over last period)
        let burnRateWindow: TimeInterval = 600 // 10 minutes
        let recentStartTime = max(block.startTime, now.addingTimeInterval(-burnRateWindow))
        let windowDuration = now.timeIntervalSince(recentStartTime) / 60.0 // minutes
        
        if windowDuration > 0 {
            let tokensPerMinute = Double(block.tokenCounts.totalTokens) / windowDuration
            let costPerHour = (block.costUSD / windowDuration) * 60.0
            
            burnRate = BurnRate(
                tokensPerMinute: tokensPerMinute,
                costPerHour: costPerHour
            )
            
            // Project usage to end of session
            let remainingMinutes = (block.endTime.timeIntervalSince(now)) / 60.0
            let projectedAdditionalTokens = Int(tokensPerMinute * remainingMinutes)
            projectedTokens = block.tokenCounts.totalTokens + projectedAdditionalTokens
            projectedCost = block.costUSD + (costPerHour * (remainingMinutes / 60.0))
        } else {
            burnRate = nil
            projectedTokens = block.tokenCounts.totalTokens
            projectedCost = block.costUSD
        }
    }
    
    func formatTokenCount(_ count: Int) -> String {
        if count >= 1000 {
            return String(format: "%.1fk", Double(count) / 1000.0)
        }
        return "\(count)"
    }
    
    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    func formatBurnRate() -> String {
        guard let rate = burnRate else { return "N/A" }
        return String(format: "%.0f/min", rate.tokensPerMinute)
    }
    
    func getUsageStatus() -> (color: Color, text: String) {
        if tokenUsagePercent > 1.0 {
            return (.red, "OVER LIMIT")
        } else if tokenUsagePercent > 0.8 {
            return (.orange, "HIGH")
        } else if tokenUsagePercent > 0.6 {
            return (.yellow, "MODERATE")
        } else {
            return (.green, "NORMAL")
        }
    }
}