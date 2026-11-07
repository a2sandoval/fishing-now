//  FishingNowWatchApp.swift — Fishing Now (Watch App)
//  Entry point. Two tabs: Play (the game) and Index (what you have caught).

import SwiftUI

@main
struct FishingNowWatchApp: App {
    @StateObject private var store = WatchStore()

    var body: some Scene {
        WindowGroup {
            TabView {
                NavigationStack {
                    GameView()
                        .environmentObject(store)
                }
                .tabItem { Label("Fish", systemImage: "fish.fill") }
                NavigationStack {
                    WatchIndexView()
                        .environmentObject(store)
                }
                .tabItem { Label("Index", systemImage: "list.bullet") }
            }
        }
    }
}
