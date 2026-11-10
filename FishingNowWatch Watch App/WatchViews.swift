//  WatchViews.swift — Fishing Now (Watch App)
//  Map picker and the on-watch Fish Index (caught species in colour,
//  uncaught ones as silhouettes — the full Index lives on the iPhone).

import SwiftUI

struct MapSelectView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        List(FishingMap.all) { map in
            let unlocked = map.isUnlocked(totalCatches: store.collection.totalCatches)
            Button {
                if unlocked { store.selectedMap = map }
            } label: {
                HStack {
                    Image(systemName: map.systemImage)
                    VStack(alignment: .leading) {
                        Text(map.name).font(.headline)
                        Text(unlocked
                             ? "\(store.collection.count(forMap: map.id)) caught here"
                             : "Unlocks at \(map.unlockCatchCount) catches")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.selectedMap.id == map.id {
                        Image(systemName: "checkmark").foregroundStyle(.green)
                    } else if !unlocked {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                    }
                }
            }
            .disabled(!unlocked)
        }
        .navigationTitle("Maps")
    }
}

struct WatchIndexView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        List {
            Section {
                Text("\(store.collection.uniqueSpeciesCaught.count) of \(FishSpecies.all.count) species")
                Text("\(store.collection.totalCatches) fish caught")
                Text(String(format: "%.0f%% complete", store.collection.completionPercent))
            } header: { Text("Collection") }

            ForEach(FishingMap.all) { map in
                Section(map.name) {
                    ForEach(map.species) { species in
                        let caught = store.collection.count(forSpecies: species.id)
                        HStack {
                            Text(caught > 0 ? species.emoji : "❓")
                            Text(caught > 0 ? species.name : "???")
                                .font(.caption)
                            Spacer()
                            if caught > 0 {
                                Text("×\(caught)").font(.caption2).foregroundStyle(.secondary)
                            } else {
                                Text(species.rarity.displayName).font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Fish Index")
    }
}
