//
//  AIStatusProvider.swift
//  AI Status Monitor Widget
//
//  Created by BUMNYEONG on 2025/07/18.
//

import Foundation
import WidgetKit

struct AIStatusProvider: TimelineProvider {
    func placeholder(in context: Context) -> AIStatusEntry {
        AIStatusEntry(
            date: Date(),
            claudeStatus: .operational,
            openAIStatus: .operational,
            geminiStatus: .operational
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (AIStatusEntry) -> ()) {
        Task {
            let entry = await fetchCurrentStatus()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<AIStatusEntry>) -> ()) {
        Task {
            let entry = await fetchCurrentStatus()
            
            // 위젯 추가 시에는 즉시 갱신, 그 외에는 5분마다 업데이트
            let updateInterval: TimeInterval = context.isPreview ? 5 * 60 : 5 * 60
            let nextUpdate = Calendar.current.date(byAdding: .second, value: Int(updateInterval), to: Date()) ?? Date()
            
            // 위젯이 처음 추가될 때는 즉시 업데이트하고, 그 다음부터는 5분 간격
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            completion(timeline)
        }
    }
    
    private func fetchCurrentStatus() async -> AIStatusEntry {
        let statusMonitor = StatusMonitor.shared
        
        // StatusMonitor의 fetchAllStatuses를 호출하여 최신 상태 업데이트
        await statusMonitor.fetchAllStatuses()
        
        // 업데이트된 상태를 반환
        return await MainActor.run {
            AIStatusEntry(
                date: Date(),
                claudeStatus: statusMonitor.claudeStatus,
                openAIStatus: statusMonitor.openAIStatus,
                geminiStatus: statusMonitor.geminiStatus
            )
        }
    }
}