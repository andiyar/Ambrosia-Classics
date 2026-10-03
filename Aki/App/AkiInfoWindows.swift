import AppKit

/// The About box and the Release Notes viewer (method-map §1 `-[Controller showAboutBox:]` @ 0x327a,
/// `-[Controller showReleaseNotes:]` @ 0x358e). 1.2 used the ASWAboutBox framework window and an
/// ASWTextViewer; the replica shows the standard AppKit About panel with the shipped credits and a
/// plain titled text window (Known delta 5, Q10 — the framework-faithful windows are a carry).
@MainActor enum AkiInfoWindows {
    /// `_releaseNotesViewer` (Controller ivar 0x1c): created on first use, then re-shown.
    private static var releaseNotesWindow: NSWindow?

    /// `showReleaseNotes:`: a titled, closable window "Aki Release Notes" (`localizedStringForKey:`)
    /// with a read-only text view of the shipped `Release Notes.rtf`. Content 480×500 is the shipped
    /// `ASWTextViewer.nib` window (ASWAppKit.framework, `NSWindowRect {{27, 646}, {480, 500}}`; a
    /// vertical-scrolling text view filling it).
    static func showReleaseNotes(controller: AkiController) {
        if releaseNotesWindow == nil {
            let rect = NSRect(x: 0, y: 0, width: 480, height: 500)
            let window = NSWindow(contentRect: rect, styleMask: [.titled, .closable], backing: .buffered, defer: true)
            window.isReleasedWhenClosed = false
            window.title = controller.assets.localized("Aki Release Notes")
            let scroll = NSScrollView(frame: rect)
            scroll.hasVerticalScroller = true
            scroll.autoresizingMask = [.width, .height]
            let text = NSTextView(frame: NSRect(origin: .zero, size: scroll.contentSize))
            text.isEditable = false
            text.autoresizingMask = [.width]
            if let url = controller.assets.url("Release Notes.rtf"), let data = try? Data(contentsOf: url),
               let notes = NSAttributedString(rtf: data, documentAttributes: nil) {
                text.textStorage?.setAttributedString(notes)
            }
            scroll.documentView = text
            window.contentView = scroll
            window.center()
            releaseNotesWindow = window
        }
        releaseNotesWindow?.makeKeyAndOrderFront(nil)
    }

    /// `showAboutBox:`: the standard About panel, credits = the shipped `AboutCredits1.rtf` from the
    /// preferred `.lproj` (English.lproj only ships it, so Japanese falls back to it).
    static func showAbout(controller: AkiController) {
        var options: [NSApplication.AboutPanelOptionKey: Any] = [:]
        if let data = try? controller.assets.lproj("AboutCredits1.rtf"),
           let credits = NSAttributedString(rtf: data, documentAttributes: nil) {
            options[.credits] = credits
        }
        NSApp.orderFrontStandardAboutPanel(options: options)
    }
}
