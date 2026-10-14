import Foundation

/// The live side of the prefs (plan O1; engine §8, save-continue §8.2): the live record `_DAT_1009fe44`, the last
/// applied music flag `*_DAT_1009fd20`, the sound scale `iRam100a510c`, `uRam100a5107` and the music player
/// (`MusicFade`), with `.MakeCurrPrefs` and the Game menu's Music (⌘M, `.ToggleMusic`) and Sound Effects (⌘F,
/// `.ToggleSound`) items. Reading and writing the prefs file stays with the caller (`.SetPrefFile` + `.InitPrefs`
/// before, `ChangedResource` + `WriteResource` after); the menus' check marks (`.UpdateMenus`) are the caller's too.
public struct PrefsToggles: Equatable, Sendable {
    /// `_DAT_1009fe44`: the live prefs (a copy of the record, 0x942 bytes).
    public var live: FerazelPrefs
    /// `*_DAT_1009fd20`: the music flag last applied (`.main` sets it to the live +0x0c at boot, M l. 8322).
    public var appliedMusicOn: UInt8
    /// `iRam100a510c`: the sound-effects play scale, +0x0e · 28.
    public var soundScale: Int
    /// `uRam100a5107` = (+0x09 == 0).
    public var wrapCopyFlag: Bool
    /// The music player (`5104`, `1992`, `5be0`, …).
    public var music: MusicFade

    /// `appliedMusicOn` defaults to `live.musicOn` (`.main`, M l. 8322).
    public init(live: FerazelPrefs, music: MusicFade = MusicFade(), appliedMusicOn: UInt8? = nil) {
        self.live = live
        self.music = music
        self.appliedMusicOn = appliedMusicOn ?? live.musicOn
        soundScale = Int(live.soundVolume) * 0x1c
        wrapCopyFlag = live.plainCopy == 0
    }

    /// `.SetMusicAIFFVolume(v) @ 100496c0` (M l. 41959–41971): `SetMovieVolume` and the current-volume global, only when
    /// QuickTime is present and a movie is loaded (`1992`) — otherwise nothing.
    mutating func setMusicVolume(_ v: Int) -> [MusicCue] {
        guard music.quickTimePresent, music.loaded else { return [] }
        music.volume = Int16(truncatingIfNeeded: v)
        return [.volume(v)]
    }

    /// `.MakeCurrPrefs @ 1000e340` (M l. 7216–7251): the record → the live prefs (0x942 bytes); `5107 = (+9 == 0)`;
    /// when not paused (`*_DAT_100a0050 == 0`) and +0x0c ≠ `fd20`: `SetMusicAIFFVolume(0)`, `SetAIFFMusic(5be0)` if on,
    /// then `SetMusicAIFFVolume(V)` (on) or `(0)` — each volume call gated on a loaded movie; `510c = +0x0e·28`;
    /// `fd20 = +0x0c` (also when paused). The output carries the cues and `prefs` (the new live copy).
    public mutating func makeCurrPrefs(_ record: FerazelPrefs, paused: Bool) -> FrontOutput {
        live = record
        wrapCopyFlag = live.plainCopy == 0
        var cues: [MusicCue] = []
        if !paused, appliedMusicOn != live.musicOn {
            cues += setMusicVolume(0)
            if live.musicOn != 0 { cues += music.setAIFFMusic(Int(music.currentTrack)) }
            cues += setMusicVolume(live.musicOn == 0 ? 0 : MusicFade.fullVolume(live))
        }
        soundScale = Int(live.soundVolume) * 0x1c
        appliedMusicOn = live.musicOn
        return FrontOutput(music: cues, prefs: live)
    }

    /// Game ▸ Music ⌘M, `.ToggleMusic @ 1000df94` (M l. 7105–7152). `record` is the prefs file's record as re-read by
    /// `.InitPrefs`; on return it is the record to write back. Off → on needs QuickTime (always present here: the
    /// "Sorry, but music requires QuickTime 2.5…" report `0x100a2fe1` is unreachable); on → off shuts the movie down
    /// (paused or not). Then `.MakeCurrPrefs`.
    public mutating func toggleMusic(_ record: inout FerazelPrefs, paused: Bool) -> FrontOutput {
        var cues: [MusicCue] = []
        if record.musicOn == 0 {
            if music.quickTimePresent { record.musicOn = 1 }
        } else {
            record.musicOn = 0
            cues = music.shutDown()
        }
        var out = FrontOutput(music: cues)
        out.append(makeCurrPrefs(record, paused: paused))
        return out
    }

    /// Game ▸ Sound Effects ⌘F, `.ToggleSound @ 1000e22c` (M l. 7185–7214): re-read record, +0x0b flipped, written
    /// back (by the caller), `.MakeCurrPrefs`.
    public mutating func toggleSound(_ record: inout FerazelPrefs, paused: Bool) -> FrontOutput {
        record.soundOn = record.soundOn == 0 ? 1 : 0
        return makeCurrPrefs(record, paused: paused)
    }
}
