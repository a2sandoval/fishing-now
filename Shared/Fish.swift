//  Fish.swift — Fishing Now (Shared by the iPhone app and the Watch app)
//  Data model for maps, species, and catches. No UI, no platform APIs,
//  so both targets can include this file unchanged.

import Foundation

public enum Rarity: String, Codable, CaseIterable, Comparable {
    case common, uncommon, rare, epic, legendary

    public var displayName: String { rawValue.capitalized }
    /// Weight used when picking which fish bites. Common fish bite most.
    public var biteWeight: Double {
        switch self {
        case .common: 55
        case .uncommon: 25
        case .rare: 12
        case .epic: 6
        case .legendary: 2
        }
    }
    /// A better cast (higher power) nudges the odds toward rarer fish.
    public var powerBonus: Double {
        switch self {
        case .common: 0
        case .uncommon: 0.15
        case .rare: 0.35
        case .epic: 0.6
        case .legendary: 1.0
        }
    }
    public var colorName: String {
        switch self {
        case .common: "gray"
        case .uncommon: "green"
        case .rare: "blue"
        case .epic: "purple"
        case .legendary: "orange"
        }
    }
    public static func < (lhs: Rarity, rhs: Rarity) -> Bool {
        allCases.firstIndex(of: lhs)! < allCases.firstIndex(of: rhs)!
    }
}

public struct FishingMap: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let detail: String
    public let systemImage: String
    /// Total catches needed (across all maps) before this map unlocks.
    public let unlockCatchCount: Int

    public init(id: String, name: String, detail: String, systemImage: String, unlockCatchCount: Int) {
        self.id = id; self.name = name; self.detail = detail
        self.systemImage = systemImage; self.unlockCatchCount = unlockCatchCount
    }

    public var species: [FishSpecies] {
        FishSpecies.all.filter { $0.mapId == id }
    }
    public func isUnlocked(totalCatches: Int) -> Bool {
        totalCatches >= unlockCatchCount
    }
}

public struct FishSpecies: Identifiable, Codable, Hashable {
    public let id: String
    public let name: String
    public let mapId: String
    public let rarity: Rarity
    public let minWeightLb: Double
    public let maxWeightLb: Double
    public let emoji: String

    public init(id: String, name: String, mapId: String, rarity: Rarity,
                minWeightLb: Double, maxWeightLb: Double, emoji: String) {
        self.id = id; self.name = name; self.mapId = mapId; self.rarity = rarity
        self.minWeightLb = minWeightLb; self.maxWeightLb = maxWeightLb; self.emoji = emoji
    }

    public var map: FishingMap? {
        FishingMap.all.first { $0.id == mapId }
    }
    public func randomWeight() -> Double {
        Double.random(in: minWeightLb...maxWeightLb)
    }
    /// How hard this fish fights: 0 (calm) to 1 (brutal). Rarity drives it.
    public var fightStrength: Double {
        switch rarity {
        case .common: Double.random(in: 0.25...0.45)
        case .uncommon: Double.random(in: 0.4...0.6)
        case .rare: Double.random(in: 0.55...0.75)
        case .epic: Double.random(in: 0.7...0.88)
        case .legendary: Double.random(in: 0.85...1.0)
        }
    }
}

public struct CaughtFish: Identifiable, Codable, Hashable {
    public let id: UUID
    public let speciesId: String
    public let weightLb: Double
    public let mapId: String
    public let caughtAt: Date
    /// Seconds from cast to catch — sessions are designed to stay under 30.
    public let sessionSeconds: Double

    public init(id: UUID = UUID(), speciesId: String, weightLb: Double,
                mapId: String, caughtAt: Date = Date(), sessionSeconds: Double) {
        self.id = id; self.speciesId = speciesId; self.weightLb = weightLb
        self.mapId = mapId; self.caughtAt = caughtAt; self.sessionSeconds = sessionSeconds
    }

    public var species: FishSpecies? {
        FishSpecies.all.first { $0.id == speciesId }
    }
}

/// The whole collection, synced between Watch and iPhone via WatchConnectivity.
/// Stored as one JSON file on each device; the newest catch wins on merge.
public struct FishCollection: Codable {
    public var catches: [CaughtFish] = []
    public var totalCasts: Int = 0

    public init() {}

    public var totalCatches: Int { catches.count }
    public var uniqueSpeciesCaught: Set<String> { Set(catches.map(\.speciesId)) }
    public var completionPercent: Double {
        guard !FishSpecies.all.isEmpty else { return 0 }
        return Double(uniqueSpeciesCaught.count) / Double(FishSpecies.all.count) * 100
    }
    public var biggestCatch: CaughtFish? {
        catches.max(by: { $0.weightLb < $1.weightLb })
    }
    public var rarestCatch: CaughtFish? {
        catches.max(by: { ($0.species?.rarity ?? .common) < ($1.species?.rarity ?? .common) })
    }
    public func isNewSpecies(_ speciesId: String) -> Bool {
        !catches.contains { $0.speciesId == speciesId }
    }
    public func count(for mapId: String) -> Int {
        catches.filter { $0.mapId == mapId }.count
    }
    public func count(for speciesId: String) -> Int {
        catches.filter { $0.speciesId == speciesId }.count
    }
    public mutating func add(_ fish: CaughtFish) { catches.append(fish) }

    /// Merge catches received from the other device, deduping by catch id.
    public mutating func merge(_ other: FishCollection) {
        let existing = Set(catches.map(\.id))
        catches.append(contentsOf: other.catches.filter { !existing.contains($0.id) })
        catches.sort(by: { $0.caughtAt < $1.caughtAt })
        totalCasts = max(totalCasts, other.totalCasts)
    }
}
