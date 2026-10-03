import AppKit

/// The splash family (method-map §2, Research note 15): `_SplashScreen` @ 0x6069 (by image name),
/// `_ShowSplashScreenWithImage` @ 0x5f06 and `_RandomProverbScreen` @ 0x60c8, over `AkiSplashWindow` /
/// `AkiSplashView` (@ 0x2a94a…0x2ac01). A borderless shadowed window of the image's size, run app-modal;
/// a click or a key closes it, and so does `timeout` seconds (0 = never). The 0.05 s idle timer runs in
/// the modal mode too, so the map keeps blinking underneath.
@MainActor enum AkiSplash {
    /// `_SplashScreen(name, timeout)`: `[NSImage imageNamed:]`; nothing happens when the image is absent.
    static func show(named name: String, timeout: Int, controller: AkiController) {
        guard let image = controller.assets.image(name) else { return }
        show(image: image, timeout: timeout, controller: controller)
    }

    /// `_ShowSplashScreenWithImage(image, timeout)`: windowed → the splash's origin is centred on the main
    /// window's frame (`(frame.size − image.size) × 0.5 + frame.origin`); fullscreen → centred on its
    /// screen and raised to `CGShieldingWindowLevel()` from inside the modal loop
    /// (`scheduleShieldingLevel`); then `runModalForWindow:`.
    static func show(image: NSImage, timeout: Int, controller: AkiController) {
        let window = AkiSplashWindow(image: image, timeout: timeout)
        if controller.shell.isFullscreen {
            window.scheduleShieldingLevel()
        } else {
            let size = image.size
            let frame = controller.shell.windowedWindow.frame
            window.setFrameOrigin(NSPoint(x: (frame.size.width - size.width) * 0.5 + frame.origin.x,
                                          y: (frame.size.height - size.height) * 0.5 + frame.origin.y))
        }
        NSApp.runModal(for: window)
    }

    /// `_RandomProverbScreen`: `random() % 11` picks one 392×157 strip of `proverbs.png` (11 × 157 = 1727),
    /// drawn with `drawInRect:{0,0,392,157} fromRect:{0, k·157, 392, 157}` (NSImage coordinates, origin
    /// bottom-left) source-over into a fresh 392×157 image, shown with a 20 s timeout.
    static func randomProverb(controller: AkiController) {
        let k = Int.random(in: 0..<11)
        let proverbs = controller.assets.image("proverbs")
        let size = NSSize(width: 392, height: 157)
        let strip = NSImage(size: size)
        if let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 392, pixelsHigh: 157,
                                      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                      colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) {
            rep.size = size
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
            proverbs?.draw(in: NSRect(x: 0, y: 0, width: 392, height: 157),
                           from: NSRect(x: 0, y: CGFloat(k * 157), width: 392, height: 157),
                           operation: .sourceOver, fraction: 1)
            NSGraphicsContext.restoreGraphicsState()
            strip.addRepresentation(rep)
        }
        show(image: strip, timeout: 20, controller: controller)
    }
}

/// `AkiSplashWindow`: borderless (style 0), buffered, not deferred, with a shadow; content view = an
/// `AkiSplashView` holding the image. Becomes key; a key down or mouse down sends `_done`.
@MainActor private final class AkiSplashWindow: NSWindow {
    /// ivar 0x84: the one-shot timeout timer (nil when timeout ≤ 0).
    private var timeoutTimer: Timer?
    /// True only inside the deliberate fullscreen centring (see `center()`).
    private var centeringOnScreen = false

    init(image: NSImage, timeout: Int) {
        super.init(contentRect: NSRect(origin: .zero, size: image.size), styleMask: [],
                   backing: .buffered, defer: false)
        isReleasedWhenClosed = false
        hasShadow = true
        let view = AkiSplashView(frame: frame)
        view.image = image
        contentView = view
        if timeout > 0 {
            // `scheduledTimerWithTimeInterval:` (default mode) and `addTimer:forMode:NSModalPanelRunLoopMode`.
            let timer = Timer.scheduledTimer(timeInterval: TimeInterval(timeout), target: self,
                                             selector: #selector(done), userInfo: nil, repeats: false)
            RunLoop.current.add(timer, forMode: .modalPanel)
            timeoutTimer = timer
        }
    }

    /// `-[AkiSplashWindow center]` @ 0x2ab35 calls super only while `[NSApp modalWindow]` is set: it blocks
    /// `runModalForWindow:`'s own centring (so a windowed splash keeps the origin centred on the main
    /// window) and lets the fullscreen `centerWithCGDisplaySize` (run inside the modal loop) through.
    /// Current AppKit sends `-center` from inside the modal session, where that test no longer tells the
    /// two callers apart (measured 2026-10-03: the splash jumped to the screen's centre), so the replica
    /// keys on the deliberate caller instead — same outcome as the original's guard.
    override func center() {
        if centeringOnScreen {
            super.center()
        }
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) { done() }

    override func mouseDown(with event: NSEvent) { done() }

    /// `-[AkiSplashWindow _done]`: invalidate the timeout, `stopModalWithCode:1`, `close`.
    @objc func done() {
        timeoutTimer?.invalidate()
        NSApp.stopModal(withCode: NSApplication.ModalResponse(rawValue: 1))
        close()
    }

    /// `centerWithCGDisplaySize` for the splash, inside the shared `scheduleShieldingLevel` pass: the one
    /// deliberate `center()` that the override above lets through (its 800×600-display-mode x correction
    /// is not replicated — Known delta 2).
    override func centerWithCGDisplaySize() {
        centeringOnScreen = true
        center()
        centeringOnScreen = false
    }
}

/// `AkiSplashView`: the image view; `mouseDown:` forwards to the window's `mouseDown:` (→ `_done`).
@MainActor private final class AkiSplashView: NSImageView {
    override func mouseDown(with event: NSEvent) {
        window?.mouseDown(with: event)
    }
}
