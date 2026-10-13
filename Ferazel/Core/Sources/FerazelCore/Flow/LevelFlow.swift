import Foundation

/// ◇ Phase-2 level flow (plan S2, W4; Ben D33): what follows the end of a `.GameLoop @ 10009d48`. The loop runs while
/// `DAT_100a5106` (game over) and `*_DAT_100a0088` (level complete) are both 0 (M l. 5229); after it (M l. 5302–5322)
/// G+4 < 1 → `*_DAT_1009ffa8 = 1`, `.FadeAIFFMusic(0, 2)`, `.DeathEffect` (the border wipe); else level complete →
/// `.EndLevelSGUpdate`, `.StageCompleteEffect`, the fades, then `.ShowWorldMap` (M l. 67465–67563), which unlocks the
/// level of `node[cur].links[exit]` (world-data §4.2). Phase 2 has neither the stage-complete screen nor the world map
/// (Phase 3): the exit loads the level it unlocks straight away, death restarts the current level with fresh globals.
public enum LevelFlow {
    /// `.FindCurrNode(hdr 0x26c4) @ 1007bb80` (M l. 67144–67163), then the level of the node at `links[exit]`
    /// (`node + 0x108 + 2·exit` → that node's `+0x102`), as `.ShowWorldMap` reads it (M l. 67513–67524). Nil when the
    /// exit is negative (`sRam100a5116 < 0`: the 25 exits with p1 −1 unlock nothing), past the seven links, when no
    /// node has the level (the original's `ReportError` + `ExitToShell`), or when the link names no existing node
    /// (link 0 = none; the original would read node 0's empty slot).
    public static func next(level: Int16, exit: Int16, map: WorldMap) -> Int16? {
        guard exit >= 0, exit < 7, let cur = map.nodes.first(where: { $0.level == level }) else { return nil }
        let link = cur.links[Int(exit)]
        guard link != 0, let n = map.nodes.first(where: { $0.index == Int(link) }) else { return nil }
        return n.level
    }

    /// The levels Phase 2 loads (D33).
    public static let phase2Levels: ClosedRange<Int> = 1...2

    /// ◇ The Phase-2 mapping (D33 seat stub): a target inside 1…2 is loaded; any other target — level 2's exits to 3
    /// and 4, or no target (an exit with p1 −1, which in the original goes to the world map) — restarts the current
    /// level.
    public static func phase2Level(next: Int16?, current: Int) -> Int {
        guard let n = next, phase2Levels.contains(Int(n)) else { return current }
        return Int(n)
    }

    /// The request a level exit makes: `.loadLevel` of the Phase-2 mapping of `next(level:exit:map:)`.
    public static func exitRequest(level: Int16, exit: Int16, map: WorldMap, current: Int) -> ShellRequest {
        .loadLevel(phase2Level(next: next(level: level, exit: exit, map: map), current: current))
    }
}

/// What the original keeps across a level load that Core rebuilds per level (plan P3 carries 1–2, W4): a new
/// `FerazelSession` takes the previous session's `carry` (A3 passes it with `rngSeed`).
public struct LevelCarry: Equatable, Sendable {
    /// `*_DAT_1009fd30`, the frame parity: only `.PaintFrameWrap` writes it, so it runs on across levels.
    public var parity: Bool
    /// `GameGlobals.crunchLog` (G+0xad6 / +0x12d8 / +0x60f8): G-resident, so it survives a level change while G
    /// lives; `.SetupLevel` re-applies a level's entries only when G+0x176 + 2·level == 1 (M l. 2382–2393) — the
    /// revisit flag, // later: Phase 3 (no Phase-2 writer).
    public var crunchLog: [CrunchLogEntry]
    /// The game globals `G` after a level EXIT (W4 review fix): `.InitGameGlobals` runs only from `.NewGame`
    /// (M l. 5747, 6707) — the next-level loop (l. 5815–5836) re-writes `+0x16` (the start facing, from the next
    /// header, l. 5821) and `.SetupLevel` `+0x20`/`+0x22`/`+0x176` (not modelled; l. 2376–2381), so score, health,
    /// breath, suffocation, max health / magic, magic, coins, `+0x12`, Xichrons and the selected slot run on (the
    /// player's HP is `G+4` again at `.SetupPlayerSprite`, l. 42831). Nil = fresh `G` (a first start, or the restart
    /// after death, D33); `crunchLog` above still rules the log.
    public var globals: GameGlobals?

    public init(parity: Bool = false, crunchLog: [CrunchLogEntry] = []) {
        self.parity = parity
        self.crunchLog = crunchLog
    }

    public init(parity: Bool, crunchLog: [CrunchLogEntry], globals: GameGlobals?) {
        self.init(parity: parity, crunchLog: crunchLog)
        self.globals = globals
    }
}
