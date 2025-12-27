import Foundation

struct DemoSegment: Codable {
    let type: String   // "inBed" | "asleep"
    let start: Date
    let end: Date
}

struct DemoNight: Codable {
    let segments: [DemoSegment]
}

enum DemoData {
    static func load() -> [SleepNight] {
        if let url = Bundle.main.url(forResource: "sleep_demo", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let nights = try? JSONDecoder.iso8601.decode([DemoNight].self, from: data) {
            return nightsToSleepNights(nights)
        } else {
            let cal = Calendar.current
            let start = cal.date(byAdding: .day, value: -10, to: Date())!
            var demo: [DemoNight] = []
            for i in 0..<10 {
                let base = cal.date(bySettingHour: 23, minute: 0, second: 0, of: start.addingTimeInterval(TimeInterval(86400*i)))!
                let bt = base.addingTimeInterval(TimeInterval(((i % 5) * 6 - 12) * 60))
                let asleepStart = bt.addingTimeInterval(TimeInterval((20 + (i % 3) * 10) * 60))
                let durHrs = 5.8 + Double(i % 5) * 0.5
                let wake = asleepStart.addingTimeInterval(durHrs * 3600)
                let inBedEnd = wake.addingTimeInterval(TimeInterval((10 + (i % 4) * 5) * 60))
                demo.append(DemoNight(segments: [
                    DemoSegment(type: "inBed", start: bt, end: inBedEnd),
                    DemoSegment(type: "asleep", start: asleepStart, end: wake)
                ]))
            }
            return nightsToSleepNights(demo)
        }
    }

    private static func nightsToSleepNights(_ src: [DemoNight]) -> [SleepNight] {
        let cal = Calendar.current
        var results: [SleepNight] = []
        for dn in src {
            let inBedDur = dn.segments.filter { $0.type == "inBed" }
                .reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
            let asleepDur = dn.segments.filter { $0.type == "asleep" }
                .reduce(0.0) { $0 + $1.end.timeIntervalSince($1.start) }
            let bedtime = dn.segments.map { $0.start }.min()
            let wake = dn.segments.map { $0.end }.max()
            let midpoint = (bedtime != nil && asleepDur > 0) ? bedtime!.addingTimeInterval(asleepDur/2) : nil
            let components = cal.dateComponents([.year, .month, .day], from: bedtime ?? Date())
            let anchor = cal.date(from: components) ?? Date()
            let eff = inBedDur > 0 ? asleepDur / inBedDur : nil
            results.append(SleepNight(date: anchor,
                                      inBed: inBedDur,
                                      asleep: asleepDur,
                                      bedtime: bedtime,
                                      wake: wake,
                                      midpoint: midpoint,
                                      efficiency: eff))
        }
        return results.sorted { $0.date > $1.date }
    }
}

extension JSONDecoder {
    static var iso8601: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}
