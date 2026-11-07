//  GameEngine.swift — Fishing Now (Shared, no UI, no platform APIs)
//  Pure game logic, so the Watch UI stays thin and the rules are testable:
//  pick a fish for a cast, time a bite, and simulate the Crown fight.
//
//  A session is designed to stay under 30 seconds:
//    cast (tap to lock power, ~2s) -> wait for a bite (1.5–4.5s)
//    -> hook window (1.2s) -> fight (reel with the Crown, ~8–18s)

import Foundation

public enum GameEngine {

    /// Pick which species bites, weighted by rarity. A stronger cast
    /// (power 0...1) slightly favours rarer fish — a perfect cast matters.
    public static func pickFish(on map: FishingMap, castPower: Double) -> FishSpecies {
        let pool = map.species
        guard !pool.isEmpty else { return FishSpecies.all.randomElement()! }
        let weighted: [(FishSpecies, Double)] = pool.map { fish in
            let w = fish.rarity.biteWeight * (1.0 + castPower * fish.rarity.powerBonus)
            return (fish, w)
        }
        let total = weighted.reduce(0) { $0 + $1.1 }
        var roll = Double.random(in: 0..<total)
        for (fish, weight) in weighted {
            roll -= weight
            if roll <= 0 { return fish }
        }
        return weighted.last!.0
    }

    /// Seconds until the bobber goes under after a cast.
    public static func biteDelay() -> Double {
        Double.random(in: 1.5...4.5)
    }

    /// How long the player has to tap after the bite before the fish leaves.
    public static let hookWindowSeconds = 1.2

    /// Whole-session cap. The Watch UI shows a countdown from this.
    public static let sessionLimitSeconds = 30.0

    // MARK: - The fight

    /// One step of the fight, called ~10x/second while reeling.
    /// - Parameters:
    ///   - reelAmount: Crown rotation accumulated since the last step (0 = not reeling).
    ///   - fishIsRunning: whether the fish is currently surging away.
    ///   - fightStrength: the hooked fish's strength, 0...1.
    ///   - progress: 0...1, how close the fish is to the boat.
    ///   - tension: 0...1, line tension. Hits 1.0 and the line snaps.
    /// - Returns: updated (progress, tension), plus whether the line snapped.
    public static func fightStep(reelAmount: Double, fishIsRunning: Bool,
                                 fightStrength: Double,
                                 progress: Double, tension: Double) -> (progress: Double, tension: Double, snapped: Bool) {
        var progress = progress
        var tension = tension

        if reelAmount > 0 {
            // Reeling gains ground, faster when the fish is not running.
            let gain = reelAmount * 0.012 * (fishIsRunning ? 0.35 : 1.0)
            progress += gain
            // Reeling against a running fish spikes tension.
            tension += reelAmount * 0.006 * (fishIsRunning ? 2.2 : 0.7) * (0.6 + fightStrength)
        } else {
            // Not reeling: the fish pulls line back, tension eases.
            progress -= 0.004 * (0.5 + fightStrength) * (fishIsRunning ? 1.6 : 1.0)
            tension -= 0.02
        }
        if fishIsRunning {
            // A surge on its own adds a little tension and pulls back.
            progress -= 0.003 * fightStrength
            tension += 0.004 * fightStrength
        }
        progress = min(1.0, max(0.0, progress))
        tension = min(1.0, max(0.0, tension))
        return (progress, tension, tension >= 1.0)
    }

    /// The fish runs in bursts: on for 0.6–1.8s, off for 0.8–2.2s.
    public static func nextRunDuration(isRunning: Bool) -> Double {
        isRunning ? Double.random(in: 0.6...1.8) : Double.random(in: 0.8...2.2)
    }

    /// Score for a catch, for the iPhone stats screen.
    public static func score(for fish: FishSpecies, weightLb: Double, sessionSeconds: Double) -> Int {
        let rarityPoints = [Rarity.common: 10, .uncommon: 25, .rare: 50, .epic: 100, .legendary: 250][fish.rarity] ?? 10
        let weightPoints = Int(weightLb * 10)
        let speedBonus = max(0, Int((30 - sessionSeconds)) * 2)
        return rarityPoints + weightPoints + speedBonus
    }
}
