import Foundation
import XCTest
@testable import AkiCore

/// P1.3 — the shipped nib XML: IB3 `designable.nib` (Cocoa) and `Aki.nib/objects.xib` (Carbon IB 2.x),
/// plan Research notes 4–7 and 20. The four data tests skip (naming AKI_DATA_12) without the 1.2.0 data.
final class NibTests: XCTestCase {

    func testIBBase64DropsTheFillerAndPads() {
        XCTAssertEqual(CocoaNib.decodeIBBase64("DQ"), "\r")
        XCTAssertEqual(CocoaNib.decodeIBBase64("Gw"), "\u{1B}")
        XCTAssertEqual(CocoaNib.decodeIBBase64("UmVnaXN0ZXIgQWtp4oCmA"), "Register Aki…")
        XCTAssertEqual(CocoaNib.decodeIBBase64("55Kw5aKD6Kit5a6aA"), "環境設定")
    }

    func testSyntheticIB3WindowOutletAndAction() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <archive type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="7.01">
          <data>
            <object class="NSMutableArray" key="IBDocument.RootObjects" id="1000">
              <object class="NSCustomObject" id="1001"><string key="NSClassName" id="9">Prefs</string></object>
              <object class="NSWindowTemplate" id="1005">
                <int key="NSWindowStyleMask">1</int>
                <string key="NSWindowRect">{{196, 376}, {410, 134}}</string>
                <reference key="NSWindowTitle" ref="9"/>
                <object class="NSView" key="NSWindowView" id="1006">
                  <object class="NSMutableArray" key="NSSubviews">
                    <object class="NSButton" id="50">
                      <string key="NSFrame">{{18, 98}, {63, 18}}</string>
                      <object class="NSButtonCell" key="NSCell" id="51">
                        <int key="NSCellFlags">-2080244224</int>
                        <string key="NSContents">Sound</string>
                        <object class="NSFont" key="NSSupport" id="52">
                          <string key="NSName">LucidaGrande</string>
                          <double key="NSSize">1.300000e+01</double>
                        </object>
                        <string type="base64-UTF8" key="NSKeyEquivalent">DQ</string>
                      </object>
                    </object>
                  </object>
                </object>
              </object>
            </object>
            <object class="IBObjectContainer" key="IBDocument.Objects">
              <object class="NSMutableArray" key="connectionRecords">
                <object class="IBConnectionRecord">
                  <object class="IBOutletConnection" key="connection">
                    <string key="label">_soundCheckbox</string>
                    <reference key="source" ref="1001"/>
                    <reference key="destination" ref="50"/>
                  </object>
                </object>
                <object class="IBConnectionRecord">
                  <object class="IBActionConnection" key="connection">
                    <string key="label">save:</string>
                    <reference key="source" ref="1001"/>
                    <reference key="destination" ref="50"/>
                  </object>
                </object>
              </object>
            </object>
          </data>
        </archive>
        """
        let nib = try CocoaNib(data: Data(xml.utf8))
        XCTAssertEqual(nib.window, CocoaNib.Window(title: "Prefs", contentWidth: 410, contentHeight: 134, styleMask: 1))
        let sound = CocoaNib.Control(className: "NSButton", x: 18, y: 98, width: 63, height: 18, title: "Sound",
                                     keyEquivalent: "\r", fontName: "LucidaGrande", fontSize: 13, isOn: true)
        XCTAssertEqual(nib.control(outlet: "_soundCheckbox"), sound)
        XCTAssertEqual(nib.control(action: "save:"), sound)
        XCTAssertNil(nib.control(outlet: "_nothing"))
        XCTAssertNil(nib.control(action: "nothing:"))
        XCTAssertThrowsError(try CocoaNib(data: Data("<plist/>".utf8))) { error in
            XCTAssertEqual(error as? CocoaNib.ParseError, .notIB3Archive)
        }
    }

    private func frame(_ c: CocoaNib.Control?) -> [Int]? { c.map { [$0.x, $0.y, $0.width, $0.height] } }

    func testEnglishPreferencesNib() throws {
        let nib = try CocoaNib(data: akiLproj("English", "Preferences.nib/designable.nib"))
        XCTAssertEqual(nib.window, CocoaNib.Window(title: "Preferences", contentWidth: 410, contentHeight: 134, styleMask: 1))
        let boxes: [(outlet: String, title: String, frame: [Int])] = [
            ("_soundCheckbox", "Sound", [18, 98, 63, 18]),
            ("_fullscreenCheckbox", "Fullscreen", [18, 78, 86, 18]),
            ("_animationCheckbox", "Tile Animation", [18, 58, 114, 18]),
            ("_musicCheckbox", "Music", [211, 98, 59, 18]),
            ("_descriptionCheckbox", "Display Level Description", [211, 78, 181, 18]),
        ]
        for box in boxes {
            let c = nib.control(outlet: box.outlet)
            XCTAssertEqual(c?.title, box.title, box.outlet)
            XCTAssertEqual(frame(c), box.frame, box.outlet)
            XCTAssertEqual(c?.className, "NSButton", box.outlet)
            XCTAssertEqual(c?.fontName, "LucidaGrande", box.outlet)
            XCTAssertEqual(c?.fontSize, 13, box.outlet)
        }
        let ok = nib.control(action: "save:")
        XCTAssertEqual(ok?.title, "OK")
        XCTAssertEqual(frame(ok), [300, 12, 96, 32])
        XCTAssertEqual(ok?.keyEquivalent, "\r")
        XCTAssertEqual(ok?.fontName, "LucidaGrande")
        XCTAssertEqual(ok?.fontSize, 13)
        let cancel = nib.control(action: "cancel:")
        XCTAssertEqual(cancel?.title, "Cancel")
        XCTAssertEqual(frame(cancel), [204, 12, 96, 32])
        XCTAssertEqual(cancel?.keyEquivalent, "\u{1B}")
    }

    func testJapanesePreferencesNibTitles() throws {
        let nib = try CocoaNib(data: akiLproj("Japanese", "Preferences.nib/designable.nib"))
        XCTAssertEqual(nib.window?.title, "環境設定")
        XCTAssertEqual(nib.control(outlet: "_musicCheckbox")?.title, "音楽")
        XCTAssertEqual(nib.control(outlet: "_fullscreenCheckbox")?.width, 127)
        XCTAssertEqual(nib.control(outlet: "_animationCheckbox")?.width, 152)
    }

    func testEnglishLevelDescriptionNib() throws {
        let nib = try CocoaNib(data: akiLproj("English", "LevelDescription.nib/designable.nib"))
        XCTAssertEqual(nib.window, CocoaNib.Window(title: "Level Description", contentWidth: 685, contentHeight: 221, styleMask: 1))
        XCTAssertEqual(frame(nib.control(outlet: "_imageView")), [20, 20, 237, 181])
        XCTAssertEqual(frame(nib.control(outlet: "_titleTextField")), [274, 184, 394, 17])
        XCTAssertEqual(frame(nib.control(outlet: "_descriptionTextField")), [274, 48, 394, 128])
        let box = nib.control(outlet: "_checkbox")
        XCTAssertEqual(frame(box), [275, 21, 181, 18])
        XCTAssertEqual(box?.title, "Display Level Description")
        XCTAssertEqual(box?.isOn, false)
        let cont = nib.control(action: "continue:")
        XCTAssertEqual(cont?.title, "Continue")
        XCTAssertEqual(frame(cont), [574, 12, 97, 32])
        XCTAssertEqual(cont?.keyEquivalent, "\r")
        let cancel = nib.control(action: "cancel:")
        XCTAssertEqual(cancel?.title, "Cancel")
        XCTAssertEqual(frame(cancel), [477, 12, 97, 32])
        XCTAssertEqual(cancel?.keyEquivalent, "\u{1B}")
    }

    func testEnglishMainMenuNib() throws {
        let nib = try CocoaNib(data: akiLproj("English", "MainMenu.nib/designable.nib"))
        XCTAssertEqual(nib.window, CocoaNib.Window(title: "Aki - Mahjong Solitaire", contentWidth: 800, contentHeight: 600, styleMask: 7))
        let menu = nib.mainMenu
        XCTAssertEqual(menu.map(\.title), ["Aki", "File", "Edit", "Level Editor", "Window", "Help"])
        func items(_ title: String) -> [CocoaNib.MenuItem] {
            (menu.first { $0.title == title }?.submenu ?? []).filter { !$0.isSeparator }
        }
        let file = items("File")
        XCTAssertEqual(file.map(\.tag), [2, 14, 18, 15, 4, 6, 7, 0, 0, 9])
        XCTAssertEqual(file.map(\.action), [String?](repeating: "gameMenuAction:", count: 7)
                       + ["performClose:", "toggleFullscreen:", "gameMenuAction:"])
        let custom = try XCTUnwrap(file.first { $0.tag == 14 })
        XCTAssertEqual(custom.title, "Play Custom Level…")
        XCTAssertEqual(custom.keyEquivalent, "N")
        XCTAssertEqual(custom.modifierMask & 0x1F0000, 0x120000)
        let aki = items("Aki")
        XCTAssertEqual(aki.map(\.action), ["showAboutBox:", "showRegistration:", "showPreferences:", "checkForUpdates:",
                                           "hide:", "hideOtherApplications:", "unhideAllApplications:", "terminate:"])
        let prefs = try XCTUnwrap(aki.first { $0.action == "showPreferences:" })
        XCTAssertEqual(prefs.keyEquivalent, ",")
        XCTAssertEqual(prefs.target, "Controller")
        XCTAssertEqual(aki.first { $0.action == "terminate:" }?.target, "FirstResponder")
        XCTAssertEqual(items("Help").map(\.action), ["showHelp:", "showHandbook:", "showReleaseNotes:"])
    }

    func testCarbonUnavailableDialog() throws {
        let nib = try CarbonNib(data: akiLproj("English", "Aki.nib/objects.xib"))
        let w = try XCTUnwrap(nib.window(named: "Unavailable"))
        XCTAssertEqual(w.title, "Level Unavailable")
        XCTAssertEqual([w.width, w.height], [344, 132])
        XCTAssertEqual(w.windowClass, 4)
        XCTAssertEqual(w.controls.map(\.kind), ["ImageView", "Button", "StaticText", "Icon"])
        let image = w.controls[0]
        XCTAssertEqual(image.controlID, 200)
        XCTAssertEqual([image.x, image.y, image.width, image.height], [0, 0, 344, 132])
        let ok = w.controls[1]
        XCTAssertEqual(ok.title, "OK")
        XCTAssertEqual([ok.x, ok.y, ok.width, ok.height], [266, 92, 58, 20])
        XCTAssertEqual(ok.command, "ok  ")
        XCTAssertEqual(ok.buttonType, 1)
        XCTAssertEqual(ok.controlID, 2)
        let text = w.controls[2]
        XCTAssertEqual(text.title, "You must complete the level(s) before this one to access this level.")
        XCTAssertEqual([text.x, text.y, text.width, text.height], [99, 20, 231, 52])
        let icon = w.controls[3]
        XCTAssertEqual(icon.contentResID, 2)
        XCTAssertEqual([icon.x, icon.y, icon.width, icon.height], [21, 14, 64, 64])
        for name in ["Warning", "Unavailable", "Stats", "Stacked", "Incomplete", "Transfer", "TryAgain",
                     "PleaseReg", "Permissions", "LoadLevel", "FileNotFound"] {
            XCTAssertNotNil(nib.window(named: name), name)
        }
        XCTAssertNil(nib.window(named: "Nonexistent"))
        XCTAssertThrowsError(try CarbonNib(data: Data("<archive/>".utf8))) { error in
            XCTAssertEqual(error as? CarbonNib.ParseError, .notCarbonNib)
        }
    }
}
