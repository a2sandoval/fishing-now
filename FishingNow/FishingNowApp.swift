//  FishingNowApp.swift — Fishing Now (iPhone companion app)
//  The iPhone app is the companion: it holds the full Fish Index, the
//  12 maps with unlock progress, and lifetime stats. The game itself
//  lives on the Watch — catches sync over automatically via
//  WatchConnectivity whenever the Watch records one.

import SwiftUI

@main
struct FishingNowApp: App {
    @StateObject private var store = PhoneStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}
