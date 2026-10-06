import Foundation
import XCTest
@testable import AkiCore

/// U3 (D11) — the Remaster setting (its own `RemasteredArt` defaults key, never the 143-byte `GameSettings`
/// blob), the art scale it selects, the files that make it available, and the Preferences row it adds.
final class RemasterTests: XCTestCase {

    /// A scratch `UserDefaults` domain kept as a plist inside a temporary directory (as
    /// `GameSettingsTests.testStoreSavesLoadsAndMigrates`), so nothing reaches `~/Library/Preferences`.
    private func withScratchDefaults(_ body: (UserDefaults) throws -> Void) throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("aki-remaster-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let suite = dir.appendingPathComponent("aki-remaster-test").path
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? FileManager.default.removeItem(at: dir)
        }
        try body(defaults)
    }

    func testKeyAndDefaultIsOriginal() throws {
        XCTAssertEqual(RemasterSetting.defaultsKey, "RemasteredArt")
        XCTAssertNotEqual(RemasterSetting.defaultsKey, GameSettings.defaultsKey)
        try withScratchDefaults { defaults in
            XCTAssertFalse(RemasterSetting(defaults: defaults).isOn)          // fresh install = Original
            XCTAssertNil(defaults.object(forKey: RemasterSetting.defaultsKey)) // reading writes nothing
        }
    }

    func testRoundTripIsABoolUnderItsOwnKey() throws {
        try withScratchDefaults { defaults in
            let setting = RemasterSetting(defaults: defaults)
            setting.isOn = true
            XCTAssertTrue(RemasterSetting(defaults: defaults).isOn)
            XCTAssertEqual(defaults.object(forKey: "RemasteredArt") as? Bool, true)
            setting.isOn = false
            XCTAssertFalse(RemasterSetting(defaults: defaults).isOn)
            XCTAssertEqual(defaults.object(forKey: "RemasteredArt") as? Bool, false)
        }
    }

    func testIndependentOfTheGameSettingsBlob() throws {
        try withScratchDefaults { defaults in
            let store = GameSettingsStore(defaults: defaults, legacyPrefsURL: nil)
            var settings = GameSettings.defaults
            settings.unlocked[3] = 1
            store.save(settings)
            let blob = try XCTUnwrap(defaults.data(forKey: GameSettings.defaultsKey))

            let setting = RemasterSetting(defaults: defaults)
            XCTAssertFalse(setting.isOn)                                      // a saved blob does not turn it on
            setting.isOn = true
            XCTAssertEqual(defaults.data(forKey: GameSettings.defaultsKey), blob)   // the blob is untouched
            XCTAssertEqual(store.load(), settings)
            store.save(GameSettings.defaults)
            XCTAssertTrue(setting.isOn)                                       // saving the blob leaves the key
        }
    }

    func testArtScaleNeedsTheSettingAndTheArt() {
        XCTAssertEqual(RemasterSetting.scale, 4)
        XCTAssertEqual(RemasterSetting.directory, "hd-4x")
        XCTAssertEqual(RemasterSetting.artScale(isOn: false, available: false), 1)
        XCTAssertEqual(RemasterSetting.artScale(isOn: false, available: true), 1)
        XCTAssertEqual(RemasterSetting.artScale(isOn: true, available: false), 1)   // the key alone is not enough
        XCTAssertEqual(RemasterSetting.artScale(isOn: true, available: true), 4)
    }

    func testRequiredFilesAreTheGWorldPNGsAndEveryBackground() {
        let gworlds = ["misc", "tiles", "proverbs", "tile_pictures", "pause", "background1", "previews",
                       "plate", "map", "nopairs", "notavail", "arrow", "layer_buttons"]
        let required = RemasterSetting.requiredFiles(gworldPNGs: gworlds)
        XCTAssertEqual(required.count, 13 + 16)                               // background1 is already a GWorld
        XCTAssertEqual(Set(required).count, required.count)
        for name in gworlds { XCTAssertTrue(required.contains("\(name).png"), name) }
        for n in 1...17 { XCTAssertTrue(required.contains("background\(n).png"), "background\(n)") }
    }

    /// The Preferences row (C6): the window grows by the nib's checkbox pitch (20), the checkboxes keep their
    /// distance from the window TOP, OK / Cancel (not passed in) keep theirs from the BOTTOM by keeping their y,
    /// and the new box sits one row below the lowest checkbox, in its column, with its font.
    func testPreferencesRowOnTheEnglishNib() throws {
        let nib = try CocoaNib(data: akiLproj("English", "Preferences.nib/designable.nib"))
        let window = try XCTUnwrap(nib.window)
        let boxes = try ["_soundCheckbox", "_fullscreenCheckbox", "_animationCheckbox", "_musicCheckbox",
                         "_descriptionCheckbox"].map { try XCTUnwrap(nib.control(outlet: $0)) }
        let layout = RemasterSetting.preferencesRow(window: window, checkboxes: boxes, title: "Remastered art")

        XCTAssertEqual(layout.pitch, 20)
        XCTAssertEqual(layout.window, CocoaNib.Window(title: "Preferences", contentWidth: 410, contentHeight: 154, styleMask: 1))
        XCTAssertEqual(layout.checkboxes.map(\.y), [118, 98, 78, 118, 98])
        XCTAssertEqual(layout.checkboxes.map(\.x), boxes.map(\.x))
        for (moved, original) in zip(layout.checkboxes, boxes) {             // distance from the top unchanged
            XCTAssertEqual(layout.window.contentHeight - moved.y, window.contentHeight - original.y)
        }
        let animation = boxes[2]                                              // Tile Animation, the lowest
        XCTAssertEqual(layout.remaster.x, animation.x)
        XCTAssertEqual(layout.remaster.y, 58)                                 // one row below Tile Animation's new 78
        XCTAssertEqual(layout.remaster.height, animation.height)
        XCTAssertEqual(layout.remaster.width, boxes.map(\.width).max())
        XCTAssertEqual(layout.remaster.fontName, animation.fontName)
        XCTAssertEqual(layout.remaster.fontSize, animation.fontSize)
        XCTAssertEqual(layout.remaster.title, "Remastered art")
        XCTAssertFalse(layout.remaster.isOn)
        let ok = try XCTUnwrap(nib.control(action: "save:"))
        XCTAssertLessThan(ok.y + ok.height, layout.remaster.y)                // clear of OK / Cancel
    }

    func testPreferencesRowOnTheJapaneseNib() throws {
        let nib = try CocoaNib(data: akiLproj("Japanese", "Preferences.nib/designable.nib"))
        let window = try XCTUnwrap(nib.window)
        let boxes = try ["_soundCheckbox", "_fullscreenCheckbox", "_animationCheckbox", "_musicCheckbox",
                         "_descriptionCheckbox"].map { try XCTUnwrap(nib.control(outlet: $0)) }
        let layout = RemasterSetting.preferencesRow(window: window, checkboxes: boxes, title: "Remastered art")
        XCTAssertEqual(layout.window.contentHeight, 154)
        XCTAssertEqual(layout.remaster.x, 18)
        XCTAssertEqual(layout.remaster.y, 58)
    }
}
