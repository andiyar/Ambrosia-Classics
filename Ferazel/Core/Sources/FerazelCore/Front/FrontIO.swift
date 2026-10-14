import Foundation

/// What the shell hands `GameFlow.tick` each tick (plan S2, FE0; LOCKED): the polled keyboard (`GetKeys`), Caps Lock,
/// the mouse in 640×480 canvas coordinates (nil outside the canvas), the button, and whether the app is active.
public struct FrontInput: Sendable {
    public var keys: KeyState
    public var capsLock: Bool
    public var mouse: (h: Int, v: Int)?
    public var button: Bool
    public var active: Bool

    public init(keys: KeyState = KeyState(), capsLock: Bool = false, mouse: (h: Int, v: Int)? = nil,
                button: Bool = false, active: Bool = true) {
        self.keys = keys
        self.capsLock = capsLock
        self.mouse = mouse
        self.button = button
        self.active = active
    }
}

/// What one front-end tick asked of the screen, the mixer, the music player and the shell (plan S2, FE0; LOCKED).
/// `soundStopAt` follows `FrameOps.soundStopAt`'s play/stop interleave rule. `present` is true on every tick that
/// changed the surface or the gamma. `prefs` is set on the tick a `.MakeCurrPrefs` ran (O1).
public struct FrontOutput: Equatable, Sendable {
    public var draws: [DrawOp]
    public var sounds: [SoundCue]
    public var soundStops: [Int16]
    public var soundStopAt: [Int]
    public var music: [MusicCue]
    public var requests: [ShellRequest]
    public var present: Bool
    public var prefs: FerazelPrefs?

    public init(draws: [DrawOp] = [], sounds: [SoundCue] = [], soundStops: [Int16] = [], soundStopAt: [Int] = [],
                music: [MusicCue] = [], requests: [ShellRequest] = [], present: Bool = false,
                prefs: FerazelPrefs? = nil) {
        self.draws = draws
        self.sounds = sounds
        self.soundStops = soundStops
        self.soundStopAt = soundStopAt
        self.music = music
        self.requests = requests
        self.present = present
        self.prefs = prefs
    }

    /// `other` appended after this tick's work (draws, cues and requests in order; `present` / `prefs` merged).
    public mutating func append(_ other: FrontOutput) {
        for (i, s) in other.soundStops.enumerated() {
            soundStops.append(s)
            soundStopAt.append(sounds.count + other.soundStopAt[i])
        }
        draws += other.draws
        sounds += other.sounds
        music += other.music
        requests += other.requests
        present = present || other.present
        if let p = other.prefs { prefs = p }
    }
}

/// A **blocking** original loop (Invariant 3) as a tick schedule: each event's work happens `at` ticks after the loop
/// began, and the flow stays blocked — no game step, no input action — for `duration` ticks. Events at
/// `at == duration` are the loop's trailing calls, made on the tick the block ends.
public struct FrontTimeline: Equatable, Sendable {
    public struct Event: Equatable, Sendable {
        public var at: Int
        public var output: FrontOutput

        public init(at: Int, output: FrontOutput) {
            self.at = at
            self.output = output
        }
    }

    public var events: [Event]
    public var duration: Int

    public init(events: [Event] = [], duration: Int = 0) {
        self.events = events
        self.duration = duration
    }

    /// The gated-off call: nothing happens and nothing blocks.
    public static let none = FrontTimeline()

    public var isEmpty: Bool { events.isEmpty && duration == 0 }
}

/// Plays a `FrontTimeline` against absolute 60 Hz ticks (`ShellClock.ticks()`); Core never reads a clock.
public struct TimelineRun: Sendable {
    public let timeline: FrontTimeline
    /// The tick the loop began.
    public let start: UInt32
    private var next = 0

    public init(_ timeline: FrontTimeline, start: UInt32) {
        self.timeline = timeline
        self.start = start
    }

    /// Ticks since `start` (wrapping, as `TickCount` differences in the original).
    private func elapsed(_ now: UInt32) -> Int { Int(now &- start) }

    /// Every event due by `now` not yet emitted, merged in order; `present` when a draw was made.
    public mutating func tick(now: UInt32) -> FrontOutput {
        var out = FrontOutput()
        let t = elapsed(now)
        while next < timeline.events.count, timeline.events[next].at <= t {
            out.append(timeline.events[next].output)
            next += 1
        }
        if !out.draws.isEmpty { out.present = true }
        return out
    }

    /// The block is over at `now` (every event emitted and `duration` ticks gone).
    public func isDone(now: UInt32) -> Bool {
        next == timeline.events.count && elapsed(now) >= timeline.duration
    }
}
