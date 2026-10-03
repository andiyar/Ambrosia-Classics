import Foundation

/// The shipped Carbon `Aki.nib/objects.xib` (Interface Builder 2.x XML, `NSIBObjectData`): the
/// dialog windows `_CreateNewDialog` opens by name through the `nameTable` (plan Research note 20).
/// Frames are `viewFrame` "x y w h", top-left origin. Holds `XMLElement`s: deliberately not `Sendable`.
public struct CarbonNib {
    public struct Window: Equatable, Sendable {
        public var title: String; public var width: Int; public var height: Int; public var windowClass: Int; public var controls: [Control]
    }
    public struct Control: Equatable, Sendable {
        public var kind: String; public var controlID: Int?; public var title: String?
        public var x: Int, y: Int, width: Int, height: Int     // top-left origin
        public var command: String?; public var buttonType: Int?; public var justification: Int?; public var controlSize: Int?; public var contentResID: Int?
    }
    public enum ParseError: Error, Equatable { case notCarbonNib }

    private let document: XMLDocument          // owns the tree the elements below live in
    private let ids: [String: XMLElement]
    private let names: [String: XMLElement]

    public init(data: Data) throws {
        guard let document = try? XMLDocument(data: data, options: [.nodePreserveWhitespace]),
              let root = document.rootElement(), root.name == "object",
              root.attribute(forName: "class")?.stringValue == "NSIBObjectData"
        else { throw ParseError.notCarbonNib }
        self.document = document
        var ids: [String: XMLElement] = [:]
        func index(_ e: XMLElement) {
            if let id = e.attribute(forName: "id")?.stringValue, ids[id] == nil { ids[id] = e }
            for child in e.children ?? [] { if let c = child as? XMLElement { index(c) } }
        }
        index(root)
        self.ids = ids
        var names: [String: XMLElement] = [:]
        if let table = Self.child(root, "nameTable") {
            let entries = (table.children ?? []).compactMap { $0 as? XMLElement }
            for pair in stride(from: 0, to: entries.count - 1, by: 2) {
                if let name = entries[pair].stringValue, let target = Self.object(entries[pair + 1], ids) { names[name] = target }
            }
        }
        self.names = names
    }

    /// The `IBCarbonWindow` the nib's `nameTable` maps `name` to; nil for unknown names / non-windows.
    public func window(named name: String) -> Window? {
        guard let w = names[name], w.attribute(forName: "class")?.stringValue == "IBCarbonWindow" else { return nil }
        let rootControl = Self.object(Self.child(w, "rootControl"), ids)
        let size = Self.numbers(rootControl.flatMap { Self.child($0, "viewFrame") }?.stringValue)
        let subviews = rootControl.flatMap { Self.child($0, "subviews") }
        let controls = (subviews?.children ?? []).compactMap { node -> Control? in
            guard let e = node as? XMLElement, let view = Self.object(e, ids) else { return nil }
            return makeControl(view)
        }
        return Window(title: Self.child(w, "title")?.stringValue ?? "",
                      width: size.count == 4 ? size[2] : 0, height: size.count == 4 ? size[3] : 0,
                      windowClass: Self.int(Self.child(w, "carbonWindowClass")) ?? 0, controls: controls)
    }

    // MARK: - Private

    private func makeControl(_ e: XMLElement) -> Control {
        var kind = e.attribute(forName: "class")?.stringValue ?? ""
        if kind.hasPrefix("IBCarbon") { kind.removeFirst("IBCarbon".count) }
        var frame = Self.numbers(Self.child(e, "viewFrame")?.stringValue)
        if frame.count != 4 { frame = [0, 0, 0, 0] }
        return Control(kind: kind, controlID: Self.int(Self.child(e, "controlID")), title: Self.child(e, "title")?.stringValue,
                       x: frame[0], y: frame[1], width: frame[2], height: frame[3],
                       command: Self.child(e, "command")?.stringValue, buttonType: Self.int(Self.child(e, "buttonType")),
                       justification: Self.int(Self.child(e, "justification")), controlSize: Self.int(Self.child(e, "controlSize")),
                       contentResID: Self.int(Self.child(e, "contentResID")))
    }

    private static func child(_ e: XMLElement, _ name: String) -> XMLElement? {
        (e.children ?? []).lazy.compactMap { $0 as? XMLElement }.first { $0.attribute(forName: "name")?.stringValue == name }
    }
    private static func object(_ e: XMLElement?, _ ids: [String: XMLElement]) -> XMLElement? {
        guard let e else { return nil }
        if e.name == "reference" { return e.attribute(forName: "idRef")?.stringValue.flatMap { ids[$0] } }
        return e
    }
    private static func int(_ e: XMLElement?) -> Int? { e?.stringValue.flatMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) } }
    private static func numbers(_ text: String?) -> [Int] { (text ?? "").split(separator: " ").compactMap { Int($0) } }
}
