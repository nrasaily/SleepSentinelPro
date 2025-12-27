import Foundation
import HealthKit
import SwiftUI
import Combine

struct SleepNight: Identifiable, Codable {
    var id: UUID = .init()
    var date: Date
    var inBed: TimeInterval?
    var asleep: TimeInterval?
    var bedtime: Date?
    var wake: Date?
    var midpoint: Date?
    var efficiency: Double?
}

struct SleepSettings: Codable {
    var targetBedtime: DateComponents
    var targetWake: DateComponents
    var midpointToleranceMinutes: Int = 45
    var remindersEnabled: Bool = false
}

@MainActor
final class SleepVM: ObservableObject {
    @Published var nights: [SleepNight] = []
    @Published var settings = SleepSettings(targetBedtime: .init(hour: 23, minute: 0),
                                           targetWake: .init(hour: 7, minute: 0))
    @Published var hkAuthorized: Bool = false
    @Published var lastUpdate: Date? = nil
    @Published var usingDemo: Bool = false
    
    private let store = HKHealthStore()
    private var anchor: HKQueryAnchor?
    
    func requestHKAuth() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Task { await self.loadDemoData() }
            return
        }
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        store.requestAuthorization(toShare: [], read: [sleepType]) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.hkAuthorized = false
                    print("HealthKit auth error:", error.localizedDescription)
                    return
                }
                self.hkAuthorized = success
                if success {
                    self.startObservers()
                    Task { @MainActor in await self.runAnchoredFetch() }
                }
            }
        }
    }
    
    func startObservers() {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        #if targetEnvironment(simulator)
        return
        #endif
        let q = HKObserverQuery(sampleType: sleepType, predicate: nil) { [weak self] _, _, _ in
            guard let self else { return }
            Task { @MainActor in
                await self.runAnchoredFetch()
            }
        }
        store.execute(q)
    }
    
    func runAnchoredFetch() async {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return }
        let handler: @Sendable (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = { [weak self] _, samples, _, newAnchor, _ in
            guard let self else { return }
            let casted = (samples as? [HKCategorySample]) ?? []
            Task { @MainActor [self, casted, newAnchor] in
                self.anchor = newAnchor
                self.process(casted)
            }
        }
        let q = HKAnchoredObjectQuery(type: sleepType,
                                      predicate: nil,
                                      anchor: anchor,
                                      limit: HKObjectQueryNoLimit,
                                      resultsHandler: handler)
        store.execute(q)
    }
    
    @MainActor private func process(_ samples: [HKCategorySample]) {
        let cal = Calendar.current
        let grouped = Dictionary(grouping: samples) { sample -> Date in
            let comps = cal.dateComponents([.year, .month, .day], from: sample.startDate)
            return cal.date(from: comps)!
        }
        for (date, segs) in grouped {
            let inBedSegs = segs.filter { $0.value == HKCategoryValueSleepAnalysis.inBed.rawValue }
            let asleepSegs = segs.filter {
                $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }
            let totalInBed = inBedSegs.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let totalAsleep = asleepSegs.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let bedtime = segs.map { $0.startDate }.min()
            let wake = segs.map { $0.endDate }.max()
            let midpoint = (bedtime != nil && totalAsleep > 0) ? bedtime!.addingTimeInterval(totalAsleep/2) : nil
            let eff = totalInBed > 0 ? totalAsleep / totalInBed : nil
            nights.append(SleepNight(date: date,
                                     inBed: totalInBed,
                                     asleep: totalAsleep,
                                     bedtime: bedtime,
                                     wake: wake,
                                     midpoint: midpoint,
                                     efficiency: eff))
        }
        nights.sort { $0.date > $1.date } // newest first
        lastUpdate = Date()
    }
    
    func exportCSV() -> URL? {
        let header = "date,inBed,asleep,bedtime,wake,midpoint,efficiency\n"
        var csv = header
        let df = ISO8601DateFormatter()
        for n in nights {
            csv += "\(df.string(from: n.date)),\(n.inBed ?? 0),\(n.asleep ?? 0),\(n.bedtime.map(df.string) ?? ""),\(n.wake.map(df.string) ?? ""),\(n.midpoint.map(df.string) ?? ""),\(n.efficiency ?? 0)\n"
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("sleep.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        return url
    }
    
    func loadDemoData() async {
        let demo = DemoData.load()
        await MainActor.run {
            self.usingDemo = true
            self.nights = demo
            self.lastUpdate = Date()
        }
    }
}
