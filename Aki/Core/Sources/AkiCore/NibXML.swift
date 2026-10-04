import Foundation

/// A minimal read-only XML element tree for the shipped nib XML, built with Foundation's SAX
/// `XMLParser` — the iOS-clean stand-in for Foundation's macOS-only DOM (the XML document tree) that
/// CocoaNib/CarbonNib were written against. It answers exactly their queries: name, attributes,
/// element children in order, `stringValue`, and a document-order descendants walk.
/// Differentially tested against that macOS DOM, whitespace-preserving (NibXMLDifferentialTests).
/// Deliberately not `Sendable` (a mutable class tree, like the DOM elements it replaces).
final class NibElement {
    let name: String
    private(set) var attributes: [String: String]
    /// Element children, in document order.
    private(set) var elements: [NibElement] = []
    /// Children of every kind, in document order (for `stringValue`).
    private var content: [Content] = []
    private weak var parent: NibElement?

    /// `.text` is one run of character data (entity / character references and CDATA sections merge into
    /// it, as the macOS DOM merges them into one text node); `.markup` is a comment's or a processing
    /// instruction's data, which the macOS DOM keeps as its own node and counts in `stringValue`.
    private enum Content { case text(String), markup(String), element(NibElement) }

    private init(name: String, attributes: [String: String], parent: NibElement?) {
        self.name = name; self.attributes = attributes; self.parent = parent
    }

    func attribute(forName name: String) -> String? { attributes[name] }

    /// The DOM `stringValue` of an element, as the macOS DOM with `.nodePreserveWhitespace`
    /// computes it on the shipped macOS: every descendant text / comment / processing-instruction data,
    /// concatenated — where a text run made only of XML whitespace (space, tab, CR, LF) is dropped, as
    /// the macOS DOM drops such text nodes at parse time. Never nil (an empty element gives "").
    var stringValue: String? {
        var out = ""
        func collect(_ e: NibElement) {
            for part in e.content {
                switch part {
                case .text(let s): if !s.unicodeScalars.allSatisfy(Self.isXMLWhitespace) { out += s }
                case .markup(let s): out += s
                case .element(let c): collect(c)
                }
            }
        }
        collect(self)
        return out
    }

    /// Every descendant (not `self`) matching `predicate`, in document order — XPath `.//…`.
    func descendants(where predicate: (NibElement) -> Bool) -> [NibElement] {
        var out: [NibElement] = []
        func walk(_ e: NibElement) {
            for c in e.elements {
                if predicate(c) { out.append(c) }
                walk(c)
            }
        }
        walk(self)
        return out
    }

    /// The root element of `data`; nil when it is not well-formed XML.
    static func parse(_ data: Data) -> NibElement? {
        let parser = XMLParser(data: data)
        parser.shouldResolveExternalEntities = false
        let builder = Builder()
        parser.delegate = builder
        guard parser.parse(), builder.current == nil else { return nil }
        return builder.root
    }

    private static func isXMLWhitespace(_ c: Unicode.Scalar) -> Bool { c == " " || c == "\t" || c == "\n" || c == "\r" }

    private func append(text: String) {
        if case .text(let previous)? = content.last { content[content.count - 1] = .text(previous + text) }
        else { content.append(.text(text)) }
    }

    private final class Builder: NSObject, XMLParserDelegate {
        var root: NibElement?
        var current: NibElement?

        func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                    qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
            let element = NibElement(name: elementName, attributes: attributeDict, parent: current)
            if let current {
                current.elements.append(element)
                current.content.append(.element(element))
            } else if root == nil {
                root = element
            }
            current = element
        }

        func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
            current = current?.parent
        }

        func parser(_ parser: XMLParser, foundCharacters string: String) { current?.append(text: string) }

        func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
            current?.append(text: String(decoding: CDATABlock, as: UTF8.self))
        }

        func parser(_ parser: XMLParser, foundComment comment: String) { current?.content.append(.markup(comment)) }

        func parser(_ parser: XMLParser, foundProcessingInstructionWithTarget target: String, data: String?) {
            current?.content.append(.markup(data ?? ""))
        }
    }
}
