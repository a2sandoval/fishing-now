//  WatchStore.swift — Fishing Now (Watch App)
//  Owns the collection on the Watch, persists it, and syncs catches
//  to the iPhone with WatchConnectivity (transferUserInfo = delivered
//  even if the phone app is not open).

import Foundation
import WatchConnectivity
import SwiftUI

final class WatchStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var collection = FishCollection()
    @Published var selectedMap: FishingMap = .all[0]

    private let fileURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fishing-now-collection.json")
    }()

    override init() {
        super.init()
        load()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - Persistence

    func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode(FishCollection.self, from: data)
        else { return }
        collection = decoded
    }

    func save() {
        guard let data = try? JSONEncoder().encode(collection) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    func recordCatch(_ fish: CaughtFish) {
        collection.add(fish)
        save()
        sendToPhone(fish)
    }

    // MARK: - WatchConnectivity

    private func sendToPhone(_ fish: CaughtFish) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(fish) else { return }
        // transferUserInfo queues and retries; the phone gets it even if
        // the iPhone app is in the background or not running.
        WCSession.default.transferUserInfo(["caughtFish": data])
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        // The phone can send back a merged collection (e.g. after a restore).
        guard let data = userInfo["collection"] as? Data,
              let incoming = try? JSONDecoder().decode(FishCollection.self, from: data)
        else { return }
        DispatchQueue.main.async {
            self.collection.merge(incoming)
            self.save()
        }
    }
}
