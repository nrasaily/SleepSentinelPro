import SwiftUI


// =============================================================
// STUDENT TODO FILE — Views.swift
// -------------------------------------------------------------
// Implement the SwiftUI views below to complete the assignment.
// Leave the types and names intact so the app wires correctly.
// Provide accessible UI where possible (VoiceOver labels).
// =============================================================

struct OnboardingView: View {
    @EnvironmentObject var vm: SleepVM
    @State private var CGFloat: CGFloat = 0
    var body: some View {
        // TODO: Replace with a friendly explainer screen that:
        // 1) Describes what data is read (Sleep Analysis only)
        
        // 2) States that all data is local and export is user-initiated
        // 3) Has a prominent "Request Health Access" button
        // 4) Optional: a secondary "Load Demo Data" button
        
        
        
        VStack(spacing: 16) {
            Text("SleepSentinel").font(.largeTitle.bold())
            // Text("Student TODO: Implement onboarding UI Tip: Call vm.requestHKAuth() to open the permission sheet.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            Text("The time you been to bed is from 7:00 PM to 5:00 AM. All Data is local and can be imported when it is authorized or imported manually." )
            HStack {
                Button("Request Health Access") { vm.requestHKAuth() }
                    .buttonStyle(.borderedProminent)
                Button("Load Demo Data") { Task { await vm.loadDemoData() } }
            }
        }.padding()
    }
}

struct MainView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        // TODO: Create actual content for each tab
        TabView {
            TrendsView()
                .tabItem { Label("Trends", systemImage: "chart.bar") }
            TimelineView()
                .tabItem { Label("Timeline", systemImage: "clock") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}


struct TrendsView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        // TODO:
        // - If vm.nights is empty: ContentUnavailableView
        // - Else: List showing date, asleep hours, efficiency%, optional midpoint
        if vm.nights.isEmpty {
            VStack(spacing: 12) {
                    Image(systemName: "bed.double.fill")
                        .font(.largeTitle)

                    Text("No Sleep Data")
                        .font(.headline)

                    Text("Sleep data will appear here once available.")
                        .foregroundColor(.secondary)
                }
        } else {
           List{
                ForEach(vm.nights) { night in
                    Text("\(night.date)")
                    Text("\(night.asleep ?? 0)")
                    Text("\(String(describing: night.midpoint))")
                    Text("\(String(describing: night.efficiency))")
                }
                
            }
        }
    }
}

struct TimelineView: View {
    @EnvironmentObject var vm: SleepVM
    var body: some View {
        // TODO:
        // - If empty: ContentUnavailableView
        // - Else: normalized bars (in-bed background, asleep foreground)
        if vm.nights.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock")
                    .font(.largeTitle)
                
                Text("No timeline available")
                    .font(.headline)
                
                Text("Add some sleep data to see a timeline.")
                    .foregroundColor(.secondary)
            }
        } else {
            GeometryReader { geo in
                ScrollView {
                    let labelWidth: CGFloat = 100
                    let maxBarWidth = geo.size.width - labelWidth - 24
                    let maxDur = max(vm.nights.compactMap{ $0.inBed ?? 0}.max() ?? 8*3600, 1)
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(vm.nights) { n in
                            let inBed = n.inBed ?? 0
                            let asleep = n.asleep ?? 0
                            let inBedW = CGFloat(inBed) / CGFloat(maxDur) * maxBarWidth
                            let asleepW = CGFloat(min(asleep, inBed)) / CGFloat(maxDur) * maxBarWidth

                            HStack(alignment: .center, spacing: 8) {
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(n.date, style: .date)
                                        .frame(width: labelWidth, alignment: .leading)
                                    Text("\(String(format: "%.1fh", asleep/3600))")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }

                                VStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gray.opacity(0.25))
                                        .frame(width: max(2, inBedW), height: 16)

                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.accentColor)
                                        .frame(width: max(2, asleepW), height: 16)
                                    
                                }
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel("In bed \(Int(inBed/3600)) hours, asleep \(Int(asleep/3600)) hours")
                                
                                
                            }
                        }

                    }
                    .padding(.horizontal, 12)
                }
            }
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var vm: SleepVM
    @State private var showShare = false
    @State private var exportURL: URL?
    var body: some View {
        // TODO:
        // - Show permission status
        VStack{
            HStack {
                Image(systemName: vm.hkAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(vm.hkAuthorized ? .green : .red)
                
                Text(vm.hkAuthorized ? "HealthKit Authorized" : "HealthKit Not Authorized")
                    .font(.subheadline)
            }
            // - "Load Demo Data" button
            Button("Load Demo Data") {
                Task {
                    await vm.loadDemoData()
                }
            }
            .buttonStyle(.bordered)
            // - "Export CSV" button using vm.exportCSV() + ShareLink
            if let url = vm.exportCSV() {
                ShareLink(item: url) {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
        }
        Form {
            Section("Permissions") {
                Text(vm.hkAuthorized ? "HealthKit: Granted" : "HealthKit: Not granted")
            }
            Section("Demo Data") {
                Toggle("Using demo", isOn: $vm.usingDemo).disabled(true)
                Button("Load Demo Data") {
                    Task { await vm.loadDemoData() }
                }
            }
            Section("Export") {
                Button("Export CSV") {
                    exportURL = vm.exportCSV()
                    showShare = true
                }
            }
        }
        .sheet(isPresented: $showShare) {
            if let exportURL {
                ShareLink(item: exportURL)
            }
        }
    }
}
