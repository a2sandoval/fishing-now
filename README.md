# Fishing Now 🎣

A casual fishing game built for the Apple Watch, with an iPhone companion
app that holds your collection. Raise your wrist, catch a fish in under
30 seconds, lower it again.

## How it plays (on the Watch)

1. **Cast — tap to lock.** A power meter sweeps 0–100%. Tap the screen to
   lock your cast. A stronger cast slightly favours rarer fish.
2. **Wait for the bite.** The bobber sits for 1.5–4.5 seconds. When it goes
   under you get a haptic tap and a big ❗ — tap within 1.2 seconds to hook.
3. **Fight — spin the Digital Crown.** The Crown *is* the reel: its haptic
   clicks are the reel's feel, and only forward spins reel line in.
   - Reel while the fish is calm and you gain ground fast.
   - Reel while it's running and line tension spikes. Stop reeling and
     tension eases, but the fish pulls line back.
   - Tension hits 100% and the line snaps. The 30-second session timer
     hits zero and the fish gets away.

Land it and the catch is saved to your Fish Index and synced to your iPhone.

## Content

- **12 maps** — Sunny Pond, Misty Lake, River Bend, Mountain Stream,
  Twilight Marsh, Golden River, Ocean Pier, Coral Reef, Tropical Lagoon,
  Midnight Bay, Frozen Lake, Hidden Cove. New maps unlock as your total
  catch count grows (5, 10, 15 … 80 catches).
- **152 fish species** — every species is unique to one map, in five
  rarities (common → legendary). Uncaught species show as ❓ in the Index.
- **iPhone companion** — full Fish Index with rarity/map filters, per-map
  completion, and lifetime stats (biggest catch, rarest catch, casts).
  Catches arrive from the Watch automatically via WatchConnectivity
  (`transferUserInfo`, so they land even if the iPhone app isn't open).

## Project layout

```
FishingNow.xcodeproj          Xcode project (2 targets, 1 scheme)
FishingNow/                   iPhone companion app (SwiftUI)
  FishingNowApp.swift
  ContentView.swift           Fish Index / Maps / Stats tabs
  PhoneStore.swift            Collection + WatchConnectivity (iPhone side)
FishingNowWatch Watch App/    Watch app (SwiftUI)
  FishingNowWatchApp.swift
  GameView.swift              Cast / wait / bite / Crown fight state machine
  WatchViews.swift            Map picker + on-watch Fish Index
  WatchStore.swift            Collection + WatchConnectivity (Watch side)
Shared/                       Included in BOTH targets — keep it platform-free
  Fish.swift                  Map / species / catch / collection models
  FishData.swift              12 maps, 152 species (generated — see tools/)
  GameEngine.swift            Fish picking, bite timing, fight simulation
tools/
  generate_fish_data.py       Regenerates Shared/FishData.swift
  generate_project.py         Regenerates FishingNow.xcodeproj/project.pbxproj
.github/workflows/build.yml  Builds the iPhone + Watch apps on GitHub Actions
```

## Run it on your Watch

This is a native Xcode project — it needs a Mac with Xcode 16+ and your
Apple ID / Developer account (the same account you use for Lumi).

1. Open `FishingNow.xcodeproj` in Xcode.
2. Select the **FishingNow** scheme. In Signing & Capabilities, set your
   Team on both targets (the bundle IDs are
   `com.a2sandoval.fishingnow` and `com.a2sandoval.fishingnow.watchkitapp` —
   change the prefix if you use a different one).
3. Plug in your iPhone, pick it as the run destination, and press Run.
   Xcode installs the iPhone app, and the Watch app installs to your paired
   Watch automatically — that's the "companion app" flow: the Watch app
   rides inside the iPhone app (the project's **Embed Watch Content**
   build phase), and the Watch app appears on your Watch once the iPhone
   app is installed. On the Watch, open the Watch app on your iPhone →
   Fishing Now → Show App on Apple Watch, if it isn't already on.
4. To play: open Fishing Now on the Watch → **Cast** → tap to lock →
   tap on the bite → spin the Crown to reel.

> I built this on a Linux VM, so I could not compile it here — no Xcode
> on this machine. The Swift is written against the watchOS 10 / iOS 17
> SwiftUI APIs (`digitalCrownRotation`, `WKInterfaceDevice` haptics,
> `WCSession.transferUserInfo`), and the GitHub Actions workflow below is
> the fastest way to prove the build: push it and watch the workflow go
> green before you run it locally. If Xcode flags anything on first open,
> tell me the exact error and I'll fix that file — don't hand-edit the
> generated `project.pbxproj`; rerun `tools/generate_project.py` after
> changing the generator.

### Build from GitHub Actions (same pattern as Lumi)

Push this folder to a repo (e.g. `a2sandoval/fishing-now`) and the
workflow builds both targets unsigned on a macOS runner:

```sh
xcodebuild -project FishingNow.xcodeproj -scheme FishingNow \
  -configuration Release -sdk iphoneos CODE_SIGNING_ALLOWED=NO build
xcodebuild -project FishingNow.xcodeproj -scheme FishingNow \
  -configuration Release -sdk watchos CODE_SIGNING_ALLOWED=NO build
```

For a signed build you can install on a real Watch, sign in Xcode with
your Developer account instead — unsigned builds can't be installed on
hardware, they only prove the code compiles.

## Tuning the game

All the numbers live in one place, `Shared/GameEngine.swift`:

- `biteDelay()` — 1.5–4.5s wait for a bite
- `hookWindowSeconds` — 1.2s to tap after the bite
- `sessionLimitSeconds` — 30s session cap
- `fightStep(...)` — reel gain, tension build-up, and snap threshold
- Rarity bite weights and cast-power bonuses live in `Shared/Fish.swift`
  (`Rarity.biteWeight` / `powerBonus`).

To add a species, add its name to `tools/generate_fish_data.py` and run it;
to add a map, add a row to `MAPS` in the same file.

## Try the mechanics now

There's also a playable watch-sized web prototype (same cast → bite →
Crown-fight loop, with the mouse wheel standing in for the Digital Crown)
in the Fishing Now web artifact — good for feeling the loop before you
build the native app.
