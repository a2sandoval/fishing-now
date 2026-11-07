//  GameView.swift — Fishing Now (Watch App)
//  The game, built for the Watch's hardware — not a phone game shrunk down:
//
//    1. CAST   — a power meter sweeps 0–100. Tap the screen to lock it.
//                A stronger cast slightly favours rarer fish.
//    2. WAIT   — the bobber sits. The bite comes 1.5–4.5s later with a
//                haptic tap and a big "!" — tap within 1.2s to hook.
//    3. FIGHT  — spin the Digital Crown to reel. The Crown's haptic
//                clicks are the reel. Reel while the fish runs and line
//                tension spikes; stop reeling and tension eases, but the
//                fish pulls line back. Land it before tension hits 100%
//                or the 30-second session timer runs out.
//
//  A whole session is under 30 seconds by design: raise your wrist,
//  catch a fish, lower it again.

import SwiftUI
import WatchKit

private enum Phase {
    case idle        // pick a map / ready to cast
    case casting     // power meter sweeping, tap to lock
    case waiting     // bobber in the water, waiting for a bite
    case bite        // fish is biting — tap NOW (1.2s window)
    case fighting    // spin the Crown to reel
    case caught(CaughtFish, Bool) // fish + whether it is a new species
    case lost(String) // "It got away…" / "Line snapped!"
}

struct GameView: View {
    @EnvironmentObject private var store: WatchStore

    @State private var phase: Phase = .idle
    @State private var castPower: Double = 0
    @State private var powerRising = true
    @State private var hookedFish: FishSpecies?
    @State private var sessionStart = Date()
    @State private var timeLeft: Double = GameEngine.sessionLimitSeconds

    // Fight state
    @State private var reelProgress: Double = 0   // 0...1, fish is landed at 1
    @State private var tension: Double = 0        // 0...1, snaps at 1
    @State private var fishIsRunning = false
    @State private var crownRotation: Double = 0
    @State private var lastCrown: Double = 0
    @State private var reelSinceLastStep: Double = 0

    @State private var biteWorkItem: DispatchWorkItem?
    @State private var hookWorkItem: DispatchWorkItem?

    // 10 ticks/second while casting or fighting.
    private let ticker = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Water gradient behind everything.
            LinearGradient(colors: [.blue.opacity(0.55), .cyan.opacity(0.35), .black],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            switch phase {
            case .idle: idleView
            case .casting: castingView
            case .waiting: waitingView
            case .bite: biteView
            case .fighting: fightingView
            case .caught(let fish, let isNew): caughtView(fish, isNew: isNew)
            case .lost(let reason): lostView(reason)
            }
        }
        // The Digital Crown drives the fight. Binding to a wide range and
        // diffing each change gives a reel amount per tick, with the
        // Crown's own haptic clicks as the reel's feel.
        .digitalCrownRotation($crownRotation, from: -1000, through: 1000,
                              by: 0.5, sensitivity: .high,
                              isContinuous: false, isHapticFeedbackEnabled: true)
        .onChange(of: crownRotation) { _, newValue in
            guard case .fighting = phase else { lastCrown = newValue; return }
            let delta = newValue - lastCrown
            lastCrown = newValue
            if delta > 0 { reelSinceLastStep += delta } // only forward spins reel in
        }
        .onReceive(ticker) { _ in tick() }
        .navigationTitle(store.selectedMap.name)
    }

    // MARK: - Views per phase

    private var idleView: some View {
        VStack(spacing: 8) {
            Text(store.selectedMap.name).font(.headline)
            Text("\(store.collection.uniqueSpeciesCaught.count)/\(FishSpecies.all.count) species")
                .font(.caption2).foregroundStyle(.secondary)
            Text("🎣").font(.system(size: 44))
            Button("Cast") { startCasting() }
                .buttonStyle(.borderedProminent)
            NavigationLink("Change map") { MapSelectView() }
                .font(.caption2)
        }
    }

    private var castingView: some View {
        VStack(spacing: 10) {
            Text("Tap to lock your cast").font(.caption).bold()
            // Power meter: fills and empties; tap anywhere to lock.
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6).fill(.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(castPower > 0.85 ? .green : castPower > 0.5 ? .yellow : .orange)
                        .frame(width: geo.size.width * castPower)
                }
            }
            .frame(height: 14)
            Text("\(Int(castPower * 100))%").font(.title3).bold().monospacedDigit()
            Text("Stronger cast, rarer fish").font(.caption2).foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { lockCast() }
    }

    private var waitingView: some View {
        VStack(spacing: 8) {
            Text("Waiting…").font(.headline)
            Text("🎣").font(.system(size: 40))
            Text("Watch for the bite").font(.caption2).foregroundStyle(.secondary)
            Text("\(Int(timeLeft))s").font(.caption).monospacedDigit()
            Button("Reel in") { cancelToIdle(reason: nil) }
                .font(.caption2)
        }
    }

    private var biteView: some View {
        VStack(spacing: 6) {
            Text("❗").font(.system(size: 52))
            Text("BITE!").font(.title2).bold()
            Text("Tap to hook it!").font(.caption)
        }
        .contentShape(Rectangle())
        .onTapGesture { hookFish() }
    }

    private var fightingView: some View {
        VStack(spacing: 8) {
            HStack {
                Text(hookedFish?.emoji ?? "🐟").font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(hookedFish?.name ?? "Fish").font(.headline).lineLimit(1)
                    Text(hookedFish?.rarity.displayName ?? "").font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(timeLeft))s").font(.caption).bold().monospacedDigit()
            }
            // Reel progress — the fish is landed at full.
            meter(label: "REEL", value: reelProgress, color: .green)
            // Tension — red zone at the top. Stop reeling while it runs.
            meter(label: "TENSION", value: tension, color: tension > 0.75 ? .red : .orange)
            Text(fishIsRunning ? "It's running! Ease off the Crown…" : "Spin the Crown to reel!")
                .font(.caption2).bold()
                .foregroundStyle(fishIsRunning ? .red : .primary)
            Text("↻ Crown").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private func meter(label: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5).fill(.white.opacity(0.2))
                    RoundedRectangle(cornerRadius: 5).fill(color)
                        .frame(width: geo.size.width * value)
                }
            }.frame(height: 10)
        }
    }

    private func caughtView(_ fish: CaughtFish, isNew: Bool) -> some View {
        VStack(spacing: 6) {
            Text(fish.species?.emoji ?? "🐟").font(.system(size: 44))
            Text(fish.species?.name ?? "Fish").font(.headline).lineLimit(1)
            Text(String(format: "%.1f lb", fish.weightLb)).font(.title3).bold()
            Text(fish.species?.rarity.displayName ?? "").font(.caption)
            if isNew {
                Text("★ NEW SPECIES!").font(.caption).bold().foregroundStyle(.yellow)
            }
            Text("\(Int(fish.sessionSeconds))s session").font(.caption2).foregroundStyle(.secondary)
            Button("Cast again") { startCasting() }.buttonStyle(.borderedProminent)
        }
    }

    private func lostView(_ reason: String) -> some View {
        VStack(spacing: 8) {
            Text("💨").font(.system(size: 40))
            Text(reason).font(.headline).multilineTextAlignment(.center)
            Button("Try again") { startCasting() }.buttonStyle(.borderedProminent)
        }
    }

    // MARK: - Game flow

    private func startCasting() {
        cancelPendingTimers()
        hookedFish = nil
        castPower = 0; powerRising = true
        reelProgress = 0; tension = 0; fishIsRunning = false
        crownRotation = 0; lastCrown = 0; reelSinceLastStep = 0
        sessionStart = Date()
        timeLeft = GameEngine.sessionLimitSeconds
        phase = .casting
        WKInterfaceDevice.current().play(.click)
    }

    private func lockCast() {
        guard case .casting = phase else { return }
        store.collection.totalCasts += 1
        phase = .waiting
        WKInterfaceDevice.current().play(.click)
        // The bite arrives after a random delay.
        let work = DispatchWorkItem { showBite() }
        biteWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + GameEngine.biteDelay(), execute: work)
    }

    private func showBite() {
        guard case .waiting = phase else { return }
        phase = .bite
        WKInterfaceDevice.current().play(.notification)
        // Miss the 1.2s hook window and the fish leaves.
        let work = DispatchWorkItem {
            if case .bite = phase { cancelToIdle(reason: "It got away…") }
        }
        hookWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + GameEngine.hookWindowSeconds, execute: work)
    }

    private func hookFish() {
        guard case .bite = phase else { return }
        hookWorkItem?.cancel()
        let fish = GameEngine.pickFish(on: store.selectedMap, castPower: castPower)
        hookedFish = fish
        reelProgress = 0; tension = 0.15
        fishIsRunning = false
        phase = .fighting
        WKInterfaceDevice.current().play(.success)
    }

    private func landFish() {
        guard let fish = hookedFish else { return }
        let seconds = Date().timeIntervalSince(sessionStart)
        let caught = CaughtFish(speciesId: fish.id, weightLb: fish.randomWeight(),
                                mapId: store.selectedMap.id, sessionSeconds: seconds)
        let isNew = store.collection.isNewSpecies(fish.id)
        store.recordCatch(caught)
        phase = .caught(caught, isNew)
        WKInterfaceDevice.current().play(.success)
    }

    private func cancelToIdle(reason: String?) {
        cancelPendingTimers()
        if let reason { phase = .lost(reason) } else { phase = .idle }
        WKInterfaceDevice.current().play(.failure)
    }

    private func cancelPendingTimers() {
        biteWorkItem?.cancel(); hookWorkItem?.cancel()
        biteWorkItem = nil; hookWorkItem = nil
    }

    // MARK: - 10x/second tick

    private func tick() {
        switch phase {
        case .casting:
            // Sweep the power meter up and down.
            castPower += powerRising ? 0.06 : -0.06
            if castPower >= 1 { castPower = 1; powerRising = false }
            if castPower <= 0 { castPower = 0; powerRising = true }
        case .waiting, .bite, .fighting:
            timeLeft -= 0.1
            if timeLeft <= 0 {
                cancelToIdle(reason: "Out of time — it got away…")
                return
            }
            if case .fighting = phase { fightTick() }
        default:
            break
        }
    }

    private func fightTick() {
        guard let fish = hookedFish else { return }
        // Fish runs in bursts; flip state on a random schedule.
        if Double.random(in: 0...1) < 0.08 {
            fishIsRunning.toggle()
            if fishIsRunning { WKInterfaceDevice.current().play(.click) }
        }
        let step = GameEngine.fightStep(reelAmount: reelSinceLastStep, fishIsRunning: fishIsRunning,
                                        fightStrength: fish.fightStrength,
                                        progress: reelProgress, tension: tension)
        reelSinceLastStep = 0
        reelProgress = step.progress
        tension = step.tension
        if step.snapped {
            cancelToIdle(reason: "Line snapped! Ease off while it runs.")
        } else if reelProgress >= 1.0 {
            landFish()
        }
    }
}
