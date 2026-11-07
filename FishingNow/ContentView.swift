//  ContentView.swift — Fishing Now (iPhone companion app)
//  Three tabs: Fish Index (the collection), Maps (12 maps + unlocks),
//  and Stats. The Watch is where you fish; this is where you admire
//  what you caught.

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PhoneStore
    @State private var indexFilter: Rarity? = nil
    @State private var mapFilter: String? = nil

    var body: some View {
        TabView {
            indexTab
                .tabItem { Label("Fish Index", systemImage: "fish.fill") }
            mapsTab
                .tabItem { Label("Maps", systemImage: "map.fill") }
            statsTab
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
        }
    }

    // MARK: - Fish Index

    private var filteredSpecies: [FishSpecies] {
        FishSpecies.all.filter { species in
            (indexFilter == nil || species.rarity == indexFilter) &&
            (mapFilter == nil || species.mapId == mapFilter)
        }
    }

    private var indexTab: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ProgressView(value: store.collection.completionPercent, total: 100)
                    .padding(.horizontal)
                Text("\(store.collection.uniqueSpeciesCaught.count) of \(FishSpecies.all.count) species — \(String(format: "%.0f%%", store.collection.completionPercent))")
                    .font(.caption).foregroundStyle(.secondary)
                    .padding(.vertical, 6)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        filterChip("All", isOn: indexFilter == nil) { indexFilter = nil }
                        ForEach(Rarity.allCases, id: \.self) { rarity in
                            filterChip(rarity.displayName, isOn: indexFilter == rarity) { indexFilter = rarity }
                        }
                    }.padding(.horizontal)
                }
                List(filteredSpecies) { species in
                    let caught = store.collection.count(for: species.id)
                    HStack {
                        Text(caught > 0 ? species.emoji : "❓").font(.title2)
                        VStack(alignment: .leading) {
                            Text(caught > 0 ? species.name : "???")
                            Text("\(species.map?.name ?? "") · \(species.rarity.displayName)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if caught > 0 {
                            Text("×\(caught)").bold()
                        } else {
                            Text("Not caught").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Fish Index")
        }
    }

    private func filterChip(_ label: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(label, action: action)
            .buttonStyle(.bordered)
            .tint(isOn ? .blue : .gray)
            .font(.caption)
    }

    // MARK: - Maps

    private var mapsTab: some View {
        NavigationStack {
            List(FishingMap.all) { map in
                let unlocked = map.isUnlocked(totalCatches: store.collection.totalCatches)
                let caughtHere = Set(store.collection.catches.filter { $0.mapId == map.id }.map(\.speciesId))
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: map.systemImage).font(.title2)
                        VStack(alignment: .leading) {
                            Text(map.name).font(.headline)
                            Text(map.detail).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !unlocked { Image(systemName: "lock.fill").foregroundStyle(.secondary) }
                    }
                    if unlocked {
                        ProgressView(value: Double(caughtHere.count), total: Double(map.species.count))
                        Text("\(caughtHere.count)/\(map.species.count) species here")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("Unlocks at \(map.unlockCatchCount) total catches — you have \(store.collection.totalCatches)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            .navigationTitle("Maps")
        }
    }

    // MARK: - Stats

    private var statsTab: some View {
        NavigationStack {
            List {
                Section("Lifetime") {
                    statRow("Fish caught", "\(store.collection.totalCatches)")
                    statRow("Casts", "\(store.collection.totalCasts)")
                    statRow("Species found", "\(store.collection.uniqueSpeciesCaught.count) / \(FishSpecies.all.count)")
                    statRow("Completion", String(format: "%.0f%%", store.collection.completionPercent))
                }
                if let biggest = store.collection.biggestCatch {
                    Section("Biggest catch") {
                        statRow(biggest.species?.name ?? "Fish", String(format: "%.1f lb", biggest.weightLb))
                    }
                }
                if let rarest = store.collection.rarestCatch {
                    Section("Rarest catch") {
                        statRow(rarest.species?.name ?? "Fish", rarest.species?.rarity.displayName ?? "")
                    }
                }
                Section {
                    Text("Fishing happens on your Apple Watch: tap to cast, spin the Digital Crown to reel. Catches appear here automatically.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("How to play") }
            }
            .navigationTitle("Stats")
        }
    }

    private func statRow(_ label: String, _ value: String) -> some View {
        HStack { Text(label); Spacer(); Text(value).bold() }
    }
}
