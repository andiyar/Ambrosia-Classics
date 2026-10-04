import AkiCore
import HectorShell

/// `_InitializeSound` @ 0x27cea and the `_PlaySound`/`_StopSound` family (method-map §2): one
/// QuickTime-style movie per effect in a `ShellSoundBank` keyed by `GameSound.rawValue` (AkiCore's
/// one id table). Volumes are QuickTime units (0x100 full, 0x80 half).
@MainActor final class AkiSound {
    /// The shipped file per id, in `_InitializeSound`'s order (assets-census §2). `tick.aiff` is
    /// never registered.
    private static let files: [(GameSound, String)] = [
        (.chime, "chime.aiff"), (.reshuffle, "Reshuffle.aiff"), (.levelComplete, "LevelComplete.aiff"),
        (.gameOver, "GameOver.aiff"), (.levelStart, "LevelStart.aiff"), (.preview, "Preview.aiff"),
        (.tileMatch, "TileMatch.aiff"), (.cancel, "cancel.aiff"), (.unclick, "unclick.aiff"),
        (.tick, "tick.mp3"), (.tilehit, "tilehit.mp3"),
    ]

    private let bank = ShellSoundBank()
    private unowned let controller: AkiController

    init(assets: AkiAssets, controller: AkiController) throws {
        self.controller = controller
        for (sound, fileName) in Self.files {
            guard let url = assets.url(fileName) else { throw AkiAssets.AssetError.missing(fileName) }
            try bank.register(id: sound.rawValue, url: url)
        }
    }

    /// `_PlaySound(id, vol)` @ 0xd28c: rewind, volume, start — only while `_p`+0x210 ≠ 0.
    func play(_ id: GameSound, volume: Int) {
        guard controller.p.soundAudible else { return }
        bank.play(id: id.rawValue, volume: volume)
    }

    /// `_StopSound(id)` @ 0xd305: `StopMovie` — only while `_p`+0x210 ≠ 0.
    func stop(_ id: GameSound) {
        guard controller.p.soundAudible else { return }
        bank.stop(id: id.rawValue)
    }

    /// `IsMovieDone` on the effect (for `_LoopSound`).
    func isDone(_ id: GameSound) -> Bool {
        bank.isDone(id: id.rawValue)
    }

    /// `GoToBeginningOfMovie` on the effect (for `_LoopSound`).
    func rewind(_ id: GameSound) {
        bank.rewind(id: id.rawValue)
    }

    /// `_LoopSound` @ 0xd21f (DC:5057), called by the game tick while b8 < 15: only while `_p`+0x210 ≠ 0;
    /// when tick.mp3 (id 100) is done it is rewound and `_PlayMovie(0x80)` runs — the MUSIC; the tick itself
    /// is not restarted (Q28). The trailing `MoviesTask` has no counterpart (AVFoundation services itself).
    func loopTick() {                                                                     // P2.10
        guard controller.p.soundAudible, isDone(.tick) else { return }
        rewind(.tick)
        controller.music.playMovie(0x80)
    }
}

/// `_InitializeMusic` @ 0x27ca2, `_PlayMovie` @ 0x2755c and `_LoopMusic(0)` @ 0x275e5 (method-map §2,
/// plan Research note 17): three tracks keyed 0/1/2; `_g`+0x5c is the current track.
@MainActor final class AkiMusic {
    /// Track id → shipped file: 0 the map theme, 1 and 2 the game themes.
    private static let tracks = ["Aki Theme 3.mp3", "Aki Theme 1.mp3", "Aki Theme 2.mp3"]

    private let bank = ShellSoundBank()
    private unowned let controller: AkiController

    init(assets: AkiAssets, controller: AkiController) throws {
        self.controller = controller
        for (id, fileName) in Self.tracks.enumerated() {
            guard let url = assets.url(fileName) else { throw AkiAssets.AssetError.missing(fileName) }
            try bank.register(id: id, url: url)
        }
    }

    /// `_PlayMovie(vol)`: the current track stops when Music is off (`_p`+0x20e < 2) or the game is
    /// paused (`_g`+0x67); otherwise volume + start from where it is (no rewind).
    func playMovie(_ volume: Int) {
        let track = controller.g.musicTrack
        if controller.p.musicFlags < 2 || controller.g.paused {
            bank.stop(id: track)
        } else {
            bank.start(id: track, volume: volume)
        }
    }

    /// `_LoopMusic(0)`, Music on only: when the current track is done, track 0 rewinds and replays;
    /// track 1 hands over to 2 and 2 to 1, the new track rewound and played — all at 0x80.
    func loopMusic() {
        guard controller.p.musicFlags > 1 else { return }
        let g = controller.g
        guard bank.isDone(id: g.musicTrack) else { return }
        switch g.musicTrack {
        case 0: break
        case 1: g.musicTrack = 2
        case 2: g.musicTrack = 1
        default: return
        }
        bank.rewind(id: g.musicTrack)
        playMovie(0x80)
    }

    /// `_StopMovie` of the current track (pause, keeping the position).
    func stopCurrent() {
        bank.stop(id: controller.g.musicTrack)
    }

    /// `_AnimationMapScreenToCustom`'s music (DC:6573–6579, DC:6587–6595): the current track stops and
    /// `_g`+0x5c = `_g`+0x5e (the last game track); then, Music on (`_p`+0x20e > 1), volume 0x80, rewind, start.
    func startGameTrack() {                                                               // P2.10
        let g = controller.g
        bank.stop(id: g.musicTrack)
        g.musicTrack = g.lastGameTrack
        guard controller.p.musicFlags > 1 else { return }
        bank.play(id: g.musicTrack, volume: 0x80)
    }

    /// `_AnimationCustomGameScreenToMap`'s bookkeeping (DC:5515–5521): `_g`+0x5e = `_g`+0x5c, `_g`+0x5c = 0
    /// (the map theme). Nothing is stopped or started here.
    func returnToMapTrack() {                                                             // P2.10
        let g = controller.g
        g.lastGameTrack = g.musicTrack
        g.musicTrack = 0
    }

    /// Music on (`_p`+0x20e > 1) → volume 0x80 and start the current track from where it is — no rewind, no
    /// paused test (`_AnimationCustomGameScreenToMap` DC:5596–5604; `_ReshuffleCustomTiles` DC:7712).
    func startCurrentIfMusicOn() {                                                        // P2.10
        guard controller.p.musicFlags > 1 else { return }
        bank.start(id: controller.g.musicTrack, volume: 0x80)
    }
}
