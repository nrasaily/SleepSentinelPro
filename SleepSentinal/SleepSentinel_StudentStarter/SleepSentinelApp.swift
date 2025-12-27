import SwiftUI

@main
struct SleepSentinelApp: App {
    @StateObject private var vm = SleepVM()
    var body: some Scene {
        WindowGroup {
            Group {
                if vm.hkAuthorized {
                    MainView()
                        .environmentObject(vm)
                        .task {
                            try? await Task.sleep(nanoseconds: 300_000_000)
                            if vm.nights.isEmpty {
                                await vm.loadDemoData()
                            }
                        }
                } else {
                    OnboardingView()
                        .environmentObject(vm)
                }
            }
        }
    }
}
