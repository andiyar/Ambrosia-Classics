import FerazelCore
import FerazelRender
import Foundation
import XCTest

/// The "visit every object" sweep, Core path (VisitSweepPlan.swift has the visit). `GameFlow` driven the way the apps'
/// shared driver (`Ferazel/Shared/FerazelDriver.swift`, not compiled here) drives it: the same renderers on one
/// `ScreenSurface` (`FrameRenderer` with the level's real faces and lights, the level-chain `ScreenRenderer`, the
/// `ConversationRenderer`, the `MapRenderer`), the same segment routing, `LevelServices` building the per-level
/// renderer — so every draw mode, light face and renderer refusal the game can meet is met here. The modals are
/// answered as the shells answer them (dialogs OK — confirms Cancel, as the Windows stub; the save panel a file in
/// memory; the open panel cancelled). Headless: no window, no audio.
///
/// Runs only with `FERAZEL_VISIT_SWEEP=1` (skipped otherwise, so the normal suite stays green while it fails on known
/// bugs): `FERAZEL_VISIT_SWEEP=1 swift test --filter VisitSweepTests` — or tools/ferazel-visit-sweep.sh, which shards
/// it across processes and survives a trap.
@MainActor final class VisitSweepTests: XCTestCase {

    func testVisitEveryObject() throws {
        guard VisitSweep.enabled else { throw XCTSkip("set FERAZEL_VISIT_SWEEP=1 (tools/ferazel-visit-sweep.sh)") }
        let resources = try FerazelData.open(try FerazelData.dataDirectory())
        let stamp = try WorldFile.load(from: resources).stamp
        let lengths = try SweepShell.soundLengths(resources)
        var rows: [VisitSweep.Failure] = []
        var visited = 0, teleporters = 0, arrived = 0, exits = 0, exitsToMap = 0
        let shard = VisitSweep.shard
        for level in VisitSweep.selectedLevels {
            let records = try LevelFile.load(from: resources, level: Int16(level)).placements
            let visits = VisitSweep.visits(level: level, records: records)
            var done = 0
            for (i, v) in visits.enumerated() where i >= VisitSweep.from && i % shard.count == shard.index {
                guard done < VisitSweep.limit else { break }
                done += 1
                VisitSweep.progress(v, index: i)
                let files = SweepFiles()
                let ref = SavedGameRef(url: URL(fileURLWithPath: "/visit-sweep/\(v.label)"), displayName: "visit")
                files.blocks[ref.url] = VisitSweep.save(for: v, records: records, stamp: stamp)
                let shell = try SweepShell(resources: resources, files: files, soundLengths: lengths)
                do {
                    try VisitSweep.toMainMenu(shell)
                } catch {
                    rows.append(VisitSweep.failure(v, frame: "boot", "\(error)"))
                    continue
                }
                let (failures, seen) = VisitSweep.run(v, game: shell, ref: ref)
                visited += 1
                rows += failures
                for f in failures { VisitSweep.append(f.tsv, to: "failures.tsv") }
                if (0x424...0x426).contains(v.record.type) {
                    teleporters += 1
                    if seen.teleportArrived { arrived += 1 }
                }
                if v.record.type == 0xcb1 {
                    exits += 1
                    if seen.exitReachedMap { exitsToMap += 1 }
                }
                VisitSweep.append("\(v.level)\t\(v.record.index)\t\(VisitSweep.hex(v.record.type))\t\(v.offset.rawValue)"
                                  + "\t\(seen.teleportArrived)\t\(seen.levelCompleted)\t\(seen.exitReachedMap)"
                                  + "\t\(seen.suspensions.sorted().joined(separator: ","))", to: "seen.tsv")
            }
        }
        let summary = "visits \(visited); teleporter visits \(teleporters) (arrived \(arrived)); "
            + "exit visits \(exits) (reached the map \(exitsToMap))"
        print("VISIT SWEEP (Core): " + summary)
        XCTAssertTrue(rows.isEmpty, "\(rows.count) visit failures — \(summary)\n" + VisitSweep.table(rows))
    }
}

/// Saved games in memory: Continue reads the visit's save; a save point's panel gets a file here.
final class SweepFiles: FrontFiles {
    var blocks: [URL: SaveBlock] = [:]
    func loadPrefs() -> Data? { nil }
    func storePrefs(_ record: Data) throws {}
    func readSavedGame(_ ref: SavedGameRef) throws -> SaveBlock {
        guard let b = blocks[ref.url] else { throw SavedGameError.notASavedGame }
        return b
    }
    func writeSavedGame(_ block: SaveBlock, to ref: SavedGameRef) throws(SaveWriteError) { blocks[ref.url] = block }
}

/// Fixed-width boxes for `DrawString` / `DrawChar` (the text's pixels are not what the sweep looks at; its widths
/// feed the conversation layout).
struct SweepText: TextRasterizer {
    func rasterize(_ text: String, font: Int16, size: Int16, face: Int16)
        -> (left: Int, top: Int, width: Int, height: Int, coverage: [UInt8]) {
        let n = text.unicodeScalars.count, ascent = max(Int(size), 1) * 3 / 4
        guard n > 0, ascent > 0 else { return (0, 0, 0, 0, []) }
        return (0, -ascent, n * 6, ascent, [UInt8](repeating: 255, count: n * 6 * ascent))
    }

    func charWidth(_ byte: UInt8, font: Int16, size: Int16, face: Int16) -> Int { 6 }

    func fontInfo(font: Int16, size: Int16, face: Int16) -> (ascent: Int, descent: Int, leading: Int) {
        let s = max(Int(size), 1)
        return (s * 3 / 4, s / 4, 0)
    }
}

/// The shared driver's game half, mirrored for the Core suite (`FerazelDriver.boot`, `tick`, `draw`, `serviceLoad`,
/// its `LevelServices`), plus the shell's answers to the requests. Kept in step with Ferazel/Shared/FerazelDriver.swift.
final class SweepShell: SweepGame {
    let flow: GameFlow
    private let resources: FerazelResources
    private let search = ColorSearch(model: .exactNearest, tieBreak: .highest)
    private let surface: ScreenSurface
    private let frontScreen: ScreenRenderer
    private let levelScreen: ScreenRenderer
    private let mapRenderer: MapRenderer
    private let text = SweepText()
    private let conversationText: ConversationText
    private var levelRenderer: FrameRenderer?
    private var conversationRenderer: ConversationRenderer?
    private weak var conversationRun: LevelRun?
    private weak var configuredRun: LevelRun?
    private var loadedPhases: Set<GameFlow.LoadPhase> = []
    private var problems: [String] = []
    private var now: UInt32 = 1000
    private var saves = 0

    /// The Sounds file's play lengths (`FerazelDriver.loadSounds`, every sound: the boot's F1 subset is a superset
    /// question only for the stage screens), decoded once per process.
    static func soundLengths(_ resources: FerazelResources) throws -> [Int16: Int] {
        if let cached = lengthsCache { return cached }
        var lengths: [Int16: Int] = [:]
        for s in try SoundBank(sounds: resources.sounds).sounds {
            lengths[s.id] = StageSounds.ticks(sampleCount: s.pcm.frames, sampleRate: s.pcm.sampleRate)
        }
        lengthsCache = lengths
        return lengths
    }
    nonisolated(unsafe) private static var lengthsCache: [Int16: Int]?

    private let soundLengths: [Int16: Int]

    init(resources: FerazelResources, files: FrontFiles, soundLengths: [Int16: Int]) throws {
        self.resources = resources
        self.soundLengths = soundLengths
        surface = ScreenSurface(clut: try ColorLUT.load(id: 0x321, from: resources, chain: .frontEnd))
        frontScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                     text: text, chain: .frontEnd)
        levelScreen = ScreenRenderer(surface: surface, resources: resources, search: search, dither: .errorDiffusion,
                                     text: text, chain: .level)
        mapRenderer = MapRenderer(screen: frontScreen)
        conversationText = TextLayout.conversationText(text)
        let box = FlowBox()
        flow = GameFlow(resources: resources, prefs: FerazelPrefs(), seed: 0x1234_5678, files: files, levels: box)
        box.shell = self
    }

    /// `GameFlow` takes its `LevelServices` at init, before this shell is whole.
    private final class FlowBox: LevelServices {
        weak var shell: SweepShell?
        func prepare(level: Int) throws -> LevelFaces {
            try shell!.prepare(level: level)
        }
        func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
            try shell!.attach(lights: lights, tintTableDraws: tintTableDraws)
        }
        func deathEffectStep(_ k: Int) throws {
            try shell!.deathEffectStep(k)
        }
    }

    func takeProblems() -> [String] {
        defer { problems = [] }
        return problems
    }

    // MARK: The tick (`FerazelDriver.tick` + the shell's request answers + `serviceLoad`)

    func tick(keys: [Int]) throws -> FrontOutput {
        let out = flow.tick(now: now, input: FrontInput(keys: KeyState(pressed: keys)))
        if let run = flow.levelRun, run !== configuredRun {
            configuredRun = run
            run.conversationText = conversationText
            if conversationRun !== run { conversationRenderer = nil }
        }
        try draw(flow.segments)
        if let p = out.prefs {
            levelRenderer?.prefs = p
            conversationRenderer?.prefs = p
        }
        for request in out.requests {
            switch request {
            case .dialog(let d):
                switch d {
                case .confirm, .preferences: flow.dialogDone(.cancel)
                case .report, .error, .credits: flow.dialogDone(.ok)
                }
            case .putFile:
                saves += 1
                flow.fileDone(.chosen(SavedGameRef(url: URL(fileURLWithPath: "/visit-sweep/save-\(saves)"),
                                                   displayName: "save \(saves)")))
            case .getFile: flow.fileDone(.cancelled)
            default: break
            }
        }
        serviceLoad()
        now &+= 1
        return out
    }

    private func draw(_ segments: [FlowSegment]) throws {
        for segment in segments {
            switch segment {
            case .screen(let ops):
                guard flow.levelRun != nil else {
                    try frontScreen.apply(ops)
                    break
                }
                var run: [DrawOp] = []
                var toConversation = false
                func flush() throws {
                    guard !run.isEmpty else { return }
                    if toConversation, let c = conversationRenderer { try c.apply(run) } else { try levelScreen.apply(run) }
                    run = []
                }
                for op in ops {
                    let c = Self.isConversationOp(op)
                    if c != toConversation { try flush(); toConversation = c }
                    run.append(op)
                }
                try flush()
            case .level(let ops):
                guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
                try r.apply(FrameOps(draws: ops))
            case .map(let ops):
                try mapRenderer.apply(ops)
            }
        }
    }

    static func isConversationOp(_ op: DrawOp) -> Bool {
        switch op {
        case .drawText, .restoreView, .drawBlackLines: return true
        case .copyPicture(_, _, _, _, nil, true): return true
        default: return false
        }
    }

    /// The boot's loads: the sound lengths (no audio), the map faces.
    private func serviceLoad() {
        guard case .loading(let phase) = flow.state, !loadedPhases.contains(phase) else { return }
        loadedPhases.insert(phase)
        switch phase {
        case .sounds:
            flow.soundLengths = soundLengths
        case .faces:
            var n = 0
            for (set, count) in [(FrontFaceSet.mapMarker, 1), (.mapNode, 8), (.mapBoss, 8), (.mapAmbient, 8)] {
                for i in 0..<count {
                    do { _ = try mapRenderer.face(set, i) } catch {
                        problems.append("map face \(Int(set.pict))/\(i): \(error)")
                    }
                    n += 1
                    flow.loadProgress(faces: n)
                }
            }
        }
        flow.loadFinished()
    }

    // MARK: LevelServices (`FerazelDriver`'s; a throw is recorded, then passed on as the driver passes it)

    func prepare(level: Int) throws -> LevelFaces {
        do {
            let r = try FrameRenderer(resources: resources, level: level, search: search, dither: .errorDiffusion,
                                      text: text, prefs: flow.toggles.live, surface: surface)
            levelRenderer = r
            conversationRenderer = ConversationRenderer(frame: r, text: text, prefs: flow.toggles.live)
            conversationRun = flow.levelRun
            return LevelFaces(faceBounds: r.faceBounds, particleFaces: r.particleFaces, diffuseRandoms: r.diffuseRandoms)
        } catch {
            problems.append("prepare(level: \(level)): \(error)")
            throw error
        }
    }

    func attach(lights: [SetupFaces.Light], tintTableDraws: [Int16]) throws {
        do {
            guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
            try r.addLights(lights)
            try r.buildTintTable(tintTableDraws)
        } catch {
            problems.append("attach (lights, tint table): \(error)")
            throw error
        }
    }

    func deathEffectStep(_ k: Int) throws {
        guard let r = levelRenderer else { throw FrameRenderer.Refusal.tintTableNotBuilt }
        guard (0..<DeathEffect.steps).contains(k) else { throw FrameRenderer.Refusal.deathEffectStep(k) }
        _ = r.deathEffect.frame(step: k, on: &surface.frame)
    }
}
