import SwiftUI

@main
struct PushWakeApp: App {
    @StateObject private var alarms = AlarmController()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(alarms)
                .preferredColorScheme(.dark)
        }
    }
}
