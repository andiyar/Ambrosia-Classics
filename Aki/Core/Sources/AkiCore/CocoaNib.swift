import Foundation

/// A shipped Interface Builder 3 `designable.nib` (plain XML, `com.apple.InterfaceBuilder3.Cocoa.XIB`)
/// read as data: the window, the controls behind outlets/actions, and the main menu (plan Research
/// notes 4–7). The 2008 keyed archives are never loaded — their classes are not ours.
/// Frames are AppKit's (bottom-left origin). Holds `XMLElement`s: deliberately not `Sendable`.
public struct CocoaNib {
    public struct Window: Equatable, Sendable {
        public var title: String; public var contentWidth: Int; public var contentHeight: Int; public var styleMask: Int
    }
    public struct Control: Equatable, Sendable {
        public var className: String; public var x: Int, y: Int, width: Int, height: Int
        public var title: String?; public var keyEquivalent: String?; public var fontName: String?; public var fontSize: Double?; public var isOn: Bool
    }
    public struct MenuItem: Equatable, Sendable {
        public var title: String; public var keyEquivalent: String; public var modifierMask: Int
        public var tag: Int; public var action: String?; public var target: String?   // "Controller" | "FirstResponder"
        public var isSeparator: Bool; public var submenu: [MenuItem]?
    }
    public enum ParseError: Error, Equatable { case notIB3Archive }

    private let document: XMLDocument          // owns the tree the elements below live in
    private let root: XMLElement
    private let ids: [String: XMLElement]
    /// Outlet label → destination element (first record wins).
    private let outlets: [String: XMLElement]
    /// Action records in file order: label, destination element, target class name.
    private let actions: [(label: String, destination: XMLElement, target: String?)]

    public init(data: Data) throws {
        guard let document = try? XMLDocument(data: data, options: [.nodePreserveWhitespace]),
              let root = document.rootElement(), root.name == "archive",
              root.attribute(forName: "type")?.stringValue == "com.apple.InterfaceBuilder3.Cocoa.XIB"
        else { throw ParseError.notIB3Archive }
        self.document = document
        self.root = root
        var ids: [String: XMLElement] = [:]
        func index(_ e: XMLElement) {
            if let id = e.attribute(forName: "id")?.stringValue, ids[id] == nil { ids[id] = e }
            for child in e.children ?? [] { if let c = child as? XMLElement { index(c) } }
        }
        index(root)
        self.ids = ids

        var outlets: [String: XMLElement] = [:]
        var actions: [(label: String, destination: XMLElement, target: String?)] = []
        let resolver = Resolver(ids: ids)
        for case let record as XMLElement in (try? root.nodes(forXPath: ".//object[@class='IBConnectionRecord']")) ?? [] {
            guard let connection = resolver.child(record, "connection"),
                  let label = resolver.string(resolver.child(connection, "label")),
                  let destination = resolver.object(resolver.child(connection, "destination")) else { continue }
            switch connection.attribute(forName: "class")?.stringValue {
            case "IBOutletConnection":
                if outlets[label] == nil { outlets[label] = destination }
            case "IBActionConnection":
                let source = resolver.object(resolver.child(connection, "source"))
                let target = source.flatMap { resolver.string(resolver.child($0, "NSClassName")) }
                actions.append((label, destination, target))
            default: continue
            }
        }
        self.outlets = outlets
        self.actions = actions
    }

    /// The first `NSWindowTemplate`: title, `NSWindowRect` size (= content size), style mask.
    public var window: Window? {
        let r = resolver
        guard let w = (try? root.nodes(forXPath: ".//object[@class='NSWindowTemplate']"))?.first as? XMLElement else { return nil }
        let rect = Self.numbers(r.string(r.child(w, "NSWindowRect")))
        return Window(title: r.string(r.child(w, "NSWindowTitle")) ?? "",
                      contentWidth: rect.count == 4 ? rect[2] : 0, contentHeight: rect.count == 4 ? rect[3] : 0,
                      styleMask: r.int(r.child(w, "NSWindowStyleMask")) ?? 0)
    }

    /// The view an outlet points at (nil when no such outlet).
    public func control(outlet: String) -> Control? { outlets[outlet].flatMap(makeControl) }

    /// The first view (not menu item) wired to `action`.
    public func control(action: String) -> Control? {
        actions.first { $0.label == action && $0.destination.attribute(forName: "class")?.stringValue != "NSMenuItem" }
            .flatMap { makeControl($0.destination) }
    }

    /// The items of the `NSMenu` titled "AMainMenu", recursively.
    public var mainMenu: [MenuItem] {
        let r = resolver
        let menus = (try? root.nodes(forXPath: ".//object[@class='NSMenu']")) ?? []
        guard let main = menus.compactMap({ $0 as? XMLElement }).first(where: { r.string(r.child($0, "NSTitle")) == "AMainMenu" })
        else { return [] }
        return menuItems(main)
    }

    /// IB's `base64-UTF8` strings: drop one trailing filler character when the length % 4 == 1, pad
    /// with "=", decode, UTF-8. nil when that is not valid base64 / UTF-8.
    public static func decodeIBBase64(_ text: String) -> String? {
        var s = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.count % 4 == 1 { s.removeLast() }
        while s.count % 4 != 0 { s += "=" }
        guard let data = Data(base64Encoded: s) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - Private

    private var resolver: Resolver { Resolver(ids: ids) }

    private func makeControl(_ e: XMLElement) -> Control? {
        let r = resolver
        guard let className = e.attribute(forName: "class")?.stringValue else { return nil }
        var frame = Self.numbers(r.string(r.child(e, "NSFrame")))
        if frame.count != 4 { frame = [0, 0] + Self.numbers(r.string(r.child(e, "NSFrameSize"))) }
        if frame.count != 4 { frame = [0, 0, 0, 0] }
        let cell = r.object(r.child(e, "NSCell"))
        let font = cell.flatMap { r.object(r.child($0, "NSSupport")) }
        let key = cell.flatMap { r.string(r.child($0, "NSKeyEquivalent")) }
        let flags = cell.flatMap { r.int(r.child($0, "NSCellFlags")) } ?? 0
        return Control(className: className, x: frame[0], y: frame[1], width: frame[2], height: frame[3],
                       title: cell.flatMap { r.string(r.child($0, "NSContents")) },
                       keyEquivalent: key?.isEmpty == false ? key : nil,
                       fontName: font.flatMap { r.string(r.child($0, "NSName")) },
                       fontSize: font.flatMap { r.double(r.child($0, "NSSize")) },
                       isOn: UInt32(truncatingIfNeeded: flags) & 0x8000_0000 != 0)
    }

    private func menuItems(_ menu: XMLElement) -> [MenuItem] {
        let r = resolver
        guard let list = r.object(r.child(menu, "NSMenuItems")) else { return [] }
        return (list.children ?? []).compactMap { node -> MenuItem? in
            guard let element = node as? XMLElement, let item = r.object(element),
                  item.attribute(forName: "class")?.stringValue == "NSMenuItem" else { return nil }
            let action = actions.first { $0.destination === item }
            return MenuItem(title: r.string(r.child(item, "NSTitle")) ?? "",
                            keyEquivalent: r.string(r.child(item, "NSKeyEquiv")) ?? "",
                            modifierMask: r.int(r.child(item, "NSKeyEquivModMask")) ?? 0,
                            tag: r.int(r.child(item, "NSTag")) ?? 0,
                            action: action?.label, target: action?.target,
                            isSeparator: r.bool(r.child(item, "NSIsSeparator")),
                            submenu: r.object(r.child(item, "NSSubmenu")).map(menuItems))
        }
    }

    /// Every integer in an IB geometry string ("{{300, 12}, {96, 32}}" → [300, 12, 96, 32]), truncated.
    private static func numbers(_ text: String?) -> [Int] {
        guard let text else { return [] }
        return text.split(whereSeparator: { !"-+.0123456789eE".contains($0) }).compactMap { Double($0).map { Int($0) } }
    }

    /// Value lookup over the IB3 XML: children by `key`, `<reference ref>` resolution, typed values.
    private struct Resolver {
        let ids: [String: XMLElement]

        func child(_ e: XMLElement, _ key: String) -> XMLElement? {
            (e.children ?? []).lazy.compactMap { $0 as? XMLElement }.first { $0.attribute(forName: "key")?.stringValue == key }
        }
        /// `<reference ref="…"/>` → the referenced element; any other element → itself; `<nil>`/dangling → nil.
        func object(_ e: XMLElement?) -> XMLElement? {
            guard let e else { return nil }
            if e.name == "reference" { return e.attribute(forName: "ref")?.stringValue.flatMap { ids[$0] } }
            return e.name == "nil" ? nil : e
        }
        func string(_ e: XMLElement?) -> String? {
            guard let e = object(e), e.name == "string" else { return nil }
            let text = e.stringValue ?? ""
            return e.attribute(forName: "type")?.stringValue == "base64-UTF8" ? CocoaNib.decodeIBBase64(text) : text
        }
        func int(_ e: XMLElement?) -> Int? {
            guard let e = object(e) else { return nil }
            let text = e.attribute(forName: "value")?.stringValue ?? e.stringValue ?? ""
            return Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        func double(_ e: XMLElement?) -> Double? {
            guard let text = object(e)?.stringValue else { return nil }
            return Double(text.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        func bool(_ e: XMLElement?) -> Bool { object(e)?.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) == "YES" }
    }
}
