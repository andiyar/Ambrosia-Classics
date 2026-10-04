#if os(macOS)
import Foundation
import XCTest
@testable import AkiCore

/// T1 (iPad plan) — the iOS-clean `NibElement` tree (Foundation `XMLParser`) against the macOS-only
/// oracle `XMLDocument(.nodePreserveWhitespace)` that CocoaNib/CarbonNib used before, over every shipped
/// nib XML the readers load: recursive element names, attribute maps, element-children order, the
/// `stringValue` of every element, and the `.//object[@class='X']` descendants walk (document order).
final class NibXMLDifferentialTests: XCTestCase {
    /// Every nib XML of the 1.2.0 bundle the readers consume (Cocoa `designable.nib`, Carbon `objects.xib`).
    private static let files = ["Aki.nib/objects.xib", "MainMenu.nib/designable.nib",
                                "Preferences.nib/designable.nib", "LevelDescription.nib/designable.nib"]

    func testEveryShippedNibMatchesXMLDocument() throws {
        var compared = 0
        for language in ["English", "Japanese"] {
            for file in Self.files {
                let data = try akiLproj(language, file)
                try compare(data, label: "\(language).lproj/\(file)")
                compared += 1
            }
        }
        XCTAssertEqual(compared, 8)
    }

    func testSyntheticEdgeCases() throws {
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <archive type="t" version="1">
          <!-- a comment -->
          <string key="a">x &amp; y &#10;&#x41; <![CDATA[<raw>]]> z</string>
          <object class="C" id="1"><object class="C" id="2"/><nil key="n"/>tail</object>
          <empty/>
          <ws> </ws><ws>&#10;</ws><ws><![CDATA[  ]]></ws><ws>\u{3000}|\u{A0}</ws>
          <mix>  <![CDATA[x]]>  </mix><mix>a<![CDATA[ ]]>b</mix><mix>  <!--c-->  x</mix><mix><!-- --></mix>
          <pi>x<?pi data?>y</pi><pi>p<?pi?>  <b/></pi><nest><b><!--n--></b>z</nest>
        </archive>
        """
        try compare(Data(xml.utf8), label: "synthetic")
    }

    func testMalformedInputIsNil() {
        XCTAssertNil(NibElement.parse(Data("not xml".utf8)))
        XCTAssertNil(NibElement.parse(Data("<a><b></a>".utf8)))
        XCTAssertNil(NibElement.parse(Data()))
    }

    // MARK: - Oracle comparison

    private func compare(_ data: Data, label: String, file: StaticString = #filePath, line: UInt = #line) throws {
        let document = try XMLDocument(data: data, options: [.nodePreserveWhitespace])
        let oracleRoot = try XCTUnwrap(document.rootElement(), label)
        let root = try XCTUnwrap(NibElement.parse(data), label)

        var oracleOrder: [XMLElement] = []
        var order: [NibElement] = []
        var mismatches = 0
        func walk(_ x: XMLElement, _ n: NibElement, _ path: String) {
            oracleOrder.append(x); order.append(n)
            func fail(_ what: String) {
                mismatches += 1
                if mismatches <= 20 { XCTFail("\(label) \(path): \(what)", file: file, line: line) }
            }
            if x.name != n.name { fail("name \(x.name ?? "nil") ≠ \(n.name)") }
            let attrs = Dictionary(uniqueKeysWithValues: (x.attributes ?? []).map { ($0.name ?? "", $0.stringValue ?? "") })
            if attrs != n.attributes { fail("attributes \(attrs) ≠ \(n.attributes)") }
            for (key, value) in attrs where n.attribute(forName: key) != value { fail("attribute(forName: \(key))") }
            if x.stringValue != n.stringValue { fail("stringValue \(String(reflecting: x.stringValue)) ≠ \(String(reflecting: n.stringValue))") }
            let xs = (x.children ?? []).compactMap { $0 as? XMLElement }
            if xs.map(\.name) != n.elements.map({ Optional($0.name) }) {
                fail("children \(xs.map { $0.name ?? "" }) ≠ \(n.elements.map(\.name))"); return
            }
            for (i, (cx, cn)) in zip(xs, n.elements).enumerated() { walk(cx, cn, "\(path)/\(cx.name ?? "")[\(i)]") }
        }
        walk(oracleRoot, root, "/\(oracleRoot.name ?? "")")
        XCTAssertEqual(mismatches, 0, "\(label): \(mismatches) mismatches", file: file, line: line)
        XCTAssertGreaterThan(order.count, 1, label, file: file, line: line)

        // The XPath `.//object[@class='X']` the readers used, for every class present (plus the root's own).
        var classes = Set(order.compactMap { $0.name == "object" ? $0.attribute(forName: "class") : nil })
        classes.insert("NSIBObjectData")
        for cls in classes.sorted() {
            let expected = try oracleRoot.nodes(forXPath: ".//object[@class='\(cls)']")
                .compactMap { node in oracleOrder.firstIndex { $0 === node } }
            let actual = root.descendants { $0.name == "object" && $0.attribute(forName: "class") == cls }
                .compactMap { element in order.firstIndex { $0 === element } }
            XCTAssertEqual(actual, expected, "\(label) .//object[@class='\(cls)']", file: file, line: line)
        }
    }
}
#endif
