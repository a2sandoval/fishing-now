//  PhoneStore.swift — Fishing Now (iPhone companion app)
//  Owns the collection on the iPhone and receives catches from the Watch.

import Foundation
import WatchConnectivity
import SwiftUI

final class PhoneStore: NSObject, ObservableObject, WCSessionDelegate {
    @Published var collection = FishCollection()

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

    // MARK: - WCSessionDelegate

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["caughtFish"] as? Data,
              let fish = try? JSONDecoder().decode(CaughtFish.self, from: data)
        else { return }
        DispatchQueue.main.async {
            // transferUserInfo can redeliver, so dedupe by catch id.
            guard !self.collection.catches.contains(where: { $0.id == fish.id }) else { return }
            self.collection.add(fish)
            self.save()
        }
    }
}
