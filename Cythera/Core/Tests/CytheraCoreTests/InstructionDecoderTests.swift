import XCTest
@testable import CytheraCore

/// C8 (docs/superpowers/plans/2026-11-05-cythera-remainder.md, Task C8): one script statement or expression at a
/// time (script-vm.md §4, §5, §8; the oracle for parity is `docs/cythera/tools/scriptdis.py`). The 0x1802 numbers
/// are the committed listing `ghidra/cythera/cythera-scripts/1802.txt` (re-checked 2026-11-05).
final class InstructionDecoderTests: XCTestCase {

    private func segment0x1802() throws -> [UInt8] {
        let r = try CytheraResources(directory: try CytheraData.dataDirectory())
        let file = try SegmentFile(contentsOf: r.segmentFileURL)
        let data = try XCTUnwrap(file.scriptSegment(0x1802), "segment 0x1802 missing from \(r.segmentFileURL.path)")
        return [UInt8](data)
    }

    private func decode(_ bytes: [UInt8], at offset: Int = 0,
                        file: StaticString = #filePath, line: UInt = #line) throws -> ScriptInstruction {
        let i = try InstructionDecoder.statement(in: bytes, at: offset)
        XCTAssertEqual(i.offset, offset, file: file, line: line)
        XCTAssertEqual(i.kind, .statement, file: file, line: line)
        XCTAssertEqual(i.flag, .reached, file: file, line: line)
        return i
    }

    private func assertStatement(_ bytes: [UInt8], _ mnemonic: String, _ length: Int, targets: [Int] = [],
                                 file: StaticString = #filePath, line: UInt = #line) {
        do {
            let i = try decode(bytes, file: file, line: line)
            XCTAssertEqual(i.mnemonic, mnemonic, "\(bytes)", file: file, line: line)
            XCTAssertEqual(i.length, length, "\(bytes)", file: file, line: line)
            XCTAssertEqual(i.jumpTargets, targets, "\(bytes)", file: file, line: line)
        } catch {
            XCTFail("\(bytes): \(error)", file: file, line: line)
        }
    }

    private func assertThrows(_ bytes: [UInt8], at offset: Int = 0, _ expected: ScriptDecodeError,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try InstructionDecoder.statement(in: bytes, at: offset), "\(bytes)",
                             file: file, line: line) { e in
            XCTAssertEqual(e as? ScriptDecodeError, expected, "\(bytes)", file: file, line: line)
        }
    }

    /// One hand-built statement per row of script-vm.md §4 (operand rules from §8 where §4 is silent).
    func testStatementOperandLengthsSynthetic() {
        assertStatement([0x00], "nop", 1)
        assertStatement([0x41, 0x42, 0x43, 0x80], "text", 3)                // pc left ON the terminator (§8)
        assertStatement([0x48, 0x69, 0x00], "text", 2)
        assertStatement([0x7F, 0x01, 0x8B], "text", 2)
        assertStatement([0x81, 0x01, 0x11], "frame", 3)
        assertStatement([0x82, 0x00, 0x41, 0x05, 0x40], "set", 5)
        assertStatement([0x82, 0x31, 0x30, 0x40], "set", 4)
        assertStatement([0x82, 0x45, 0x41], "set", 2)                       // slot ≥ 0x40: the slot byte only (§8)
        assertStatement([0x83, 0x00, 0x10, 0x41, 0x01, 0x40], "store", 6)
        assertStatement([0x84, 0x01, 0x40, 0x41, 0x02, 0x40, 0x42, 0x01, 0x00, 0x40], "atput", 10)
        assertStatement([0x85, 0x12, 0x34, 0x00, 0x08, 0x41, 0x01, 0x40], "gstore", 8)
        assertStatement([0x86, 0x23, 0x30, 0x40, 0x41, 0x64, 0x40], "setfield", 7)
        assertStatement([0x87, 0x11, 0x41, 0x02, 0x40], "setglobal", 5)
        assertStatement([0x88, 0x07, 0x1C], "goto", 3, targets: [0x071C])
        assertStatement([0x89, 0x00, 0x40, 0x00, 0x02, 0x00, 0x10, 0x00, 0x20], "switch", 9, targets: [0x10, 0x20])
        assertStatement([0x89, 0x00, 0x40, 0x00, 0x00], "switch", 5)
        assertStatement([0x8A, 0x41, 0x01, 0x40], "print", 4)
        assertStatement([0x8B, 0x41, 0x00, 0x40], "return", 4)
        assertStatement([0x8C, 0x00, 0x40, 0x01, 0x00], "jt", 5, targets: [0x0100])
        assertStatement([0x8D, 0x00, 0x5E, 0x40, 0x02, 0xF8], "jf", 6, targets: [0x02F8])
        assertStatement([0x8E], "input", 1)
        assertStatement([0x8F, 0x2A, 0x79, 0x00], "prompt", 4)              // terminator skipped (§8)
        assertStatement([0x8F, 0x61, 0x62, 0x88], "prompt", 4)
        assertStatement([0x90, 0x79, 0x65, 0x73, 0x2C, 0x6E, 0x6F, 0x00, 0x01, 0x23], "match", 10, targets: [0x0123])
        assertStatement([0x91], "nop91", 1)
        assertStatement([0x92, 0x03, 0x41, 0x01, 0x40], "raise", 5)
        assertStatement([0x93, 0x00, 0x40], "release", 3)
        assertStatement([0x9B, 0x06, 0x41, 0x01, 0x40], "sysnew", 5)
        assertStatement([0x9C, 0x0F, 0x00, 0x41, 0x02, 0x40, 0x30, 0x40], "call", 8)   // seg + constant int
        assertStatement([0x9C, 0x0F, 0x00, 0x43, 0x00, 0x00, 0x00, 0x02, 0x40, 0x30, 0x40], "call", 11)  // tag-0 0x43
        assertStatement([0x9C, 0x0F, 0x00, 0x43, 0x10, 0x00, 0x00, 0x02, 0x40, 0x30, 0x40], "callx", 11) // tag-1 0x43
        assertStatement([0x9C, 0x0F, 0x00, 0x01, 0x40, 0x30, 0x40], "callx", 7)        // seg + computed int
        assertStatement([0x9C, 0xFF, 0xFF, 0x08, 0x40, 0x30, 0x40], "callx", 7)        // FFFF: target + args
        assertStatement([0x9D, 0x0C, 0x30, 0x40], "send", 4)
        assertStatement([0x9E, 0x00, 0x60, 0x30, 0x40], "callsub", 5)
        assertStatement([0x9F, 0x0F, 0x02, 0x30, 0x41, 0x01, 0x40], "call", 7)
        assertStatement([0xD9, 0x41, 0x00, 0x40], "builtin", 4)

        // Every row of the statement table has a form; the invalid rows are exactly 0x80, 0x94–0x9A (and 0xFF).
        let invalid = (0...0xFF).filter { ScriptOpcodes.statement(UInt8($0)).form == .invalid }
        XCTAssertEqual(invalid, [0x80] + Array(0x94...0x9A))
        XCTAssertEqual(ScriptOpcodes.statement(0xFF).form, .nullBuiltin)
    }

    /// script-vm.md §5 worked decode: `local0 = Routine0F02(arg0, 1)`.
    func testExpressionWorkedDecode() throws {
        let bytes: [UInt8] = [0x82, 0x00, 0x9F, 0x0F, 0x02, 0x30, 0x41, 0x01, 0x40, 0x40]
        let i = try decode(bytes)
        XCTAssertEqual(i.mnemonic, "set")
        XCTAssertEqual(i.length, 10)
        XCTAssertEqual(i.jumpTargets, [])
        XCTAssertEqual(try InstructionDecoder.expressionEnd(in: bytes, at: 2), 10)   // the assigned expression
        XCTAssertEqual(try InstructionDecoder.expressionEnd(in: bytes, at: 5), 9)    // 0x9F's own argument list

        // The same bytes in place in 0x1802 (@02C4, the talk method).
        let seg = try segment0x1802()
        XCTAssertEqual(Array(seg[0x02C4..<0x02CE]), bytes)
        let s = try decode(seg, at: 0x02C4)
        XCTAssertEqual(s.mnemonic, "set")
        XCTAssertEqual(s.length, 10)
    }

    /// The head of 0x1802 (class 0x40 id 2): the method sel 32 @002A, decoded statement by statement.
    func testSegment0x1802Head() throws {
        let seg = try segment0x1802()
        XCTAssertEqual(seg.count, 10426)
        // The three literal lines (C9's segment-level `.hdr` / `.array` ×2) as byte ranges.
        XCTAssertEqual(Int(seg[0]) << 8 | Int(seg[1]), 0x288E)                       // .hdr @0000 len 2
        XCTAssertTrue((0x90...0x9F).contains(seg[2]))
        XCTAssertEqual((Int(seg[2]) << 8 | Int(seg[3])) & 0xFFF, 1)                  // .array @0002: 2 + 4×1 = 6
        XCTAssertTrue((0x90...0x9F).contains(seg[8]))
        XCTAssertEqual((Int(seg[8]) << 8 | Int(seg[9])) & 0xFFF, 8)                  // .array @0008: 2 + 4×8 = 34
        XCTAssertEqual(0x0008 + 34, 0x002A)

        let expected: [(Int, String, Int, [Int])] = [
            (0x002A, "frame", 3, []),
            (0x002D, "jf", 23, [0x005C]),
            (0x0044, "setfield", 10, []),
            (0x004E, "setfield", 7, []),
            (0x0055, "return", 7, []),
            (0x005C, "return", 4, []),
        ]
        var pc = 0x002A
        for (offset, mnemonic, length, targets) in expected {
            XCTAssertEqual(pc, offset)
            let i = try decode(seg, at: pc)
            XCTAssertEqual(i.mnemonic, mnemonic, String(offset, radix: 16))
            XCTAssertEqual(i.length, length, String(offset, radix: 16))
            XCTAssertEqual(i.jumpTargets, targets, String(offset, radix: 16))
            pc += i.length
        }
        XCTAssertEqual(pc, 0x0060)
        XCTAssertEqual(Array(seg[0x002A..<0x002D]), [0x81, 0x01, 0x00])               // args 1 locals 0
    }

    /// Literal text runs to the first byte that is 0 or ≥ 0x80 and leaves the pc ON it (script-vm.md §8).
    func testTextStatementLength() throws {
        let seg = try segment0x1802()
        let frame = try decode(seg, at: 0x0060)
        XCTAssertEqual(frame.mnemonic, "frame")
        XCTAssertEqual(frame.length, 3)
        let text = try decode(seg, at: 0x0063)
        XCTAssertEqual(text.mnemonic, "text")
        XCTAssertEqual(text.length, 555)
        XCTAssertEqual(0x0063 + text.length, 0x028E)
        let ret = try decode(seg, at: 0x028E)
        XCTAssertEqual(ret.mnemonic, "return")
        XCTAssertEqual(ret.length, 4)

        // The reviewer's prediction: @02D4 is a text of 33 bytes with the pc left on 0x88 (goto 071C).
        let tail = try decode(seg, at: 0x02D4)
        XCTAssertEqual(tail.mnemonic, "text")
        XCTAssertEqual(tail.length, 33)
        XCTAssertEqual(seg[0x02D4 + 33], 0x88)
        let goto = try decode(seg, at: 0x02F5)
        XCTAssertEqual(goto.mnemonic, "goto")
        XCTAssertEqual(goto.jumpTargets, [0x071C])
    }

    /// Builtins: the statement form and the expression form take one argument expression each (§6, §8).
    func testBuiltinForms() throws {
        XCTAssertEqual(BuiltinNames.names.count, 95)
        XCTAssertEqual(BuiltinNames.name(0xA0), "iterate_range")
        XCTAssertEqual(BuiltinNames.name(0xAC), "random")
        XCTAssertEqual(BuiltinNames.name(0xD9), "set_outdoor_sky")
        XCTAssertEqual(BuiltinNames.name(0xFE), "stub_fe")
        XCTAssertNil(BuiltinNames.name(0xFF))
        XCTAssertNil(BuiltinNames.name(0x9F))

        // Statement form: `d9 41 00 40` = set_outdoor_sky(0), 8 shipped sites.
        let sky = try decode([0xD9, 0x41, 0x00, 0x40])
        XCTAssertEqual(sky.mnemonic, "builtin")
        XCTAssertEqual(sky.length, 4)

        // Expression form inside 0x1802's `jf` @002D: `ac 41 00 41 04 40` = random(0, 4) @0037.
        let seg = try segment0x1802()
        XCTAssertEqual(Array(seg[0x0037..<0x003D]), [0xAC, 0x41, 0x00, 0x41, 0x04, 0x40])
        XCTAssertEqual(try InstructionDecoder.expressionEnd(in: seg, at: 0x0038), 0x003D)   // its own 0x40
        XCTAssertEqual(try InstructionDecoder.expressionEnd(in: seg, at: 0x002E), 0x0042)   // the jf condition
        XCTAssertEqual(Int(seg[0x0042]) << 8 | Int(seg[0x0043]), 0x005C)
        // The same call as a statement has the same operand length.
        let random = try decode(Array(seg[0x0037..<0x003D]))
        XCTAssertEqual(random.mnemonic, "builtin")
        XCTAssertEqual(random.length, 6)
    }

    /// Invalid opcodes, 0xFF and truncation throw named errors; nothing traps (Invariants 3, 4).
    func testInvalidOpcodesRefused() throws {
        for op in [0x80] + Array(0x94...0x9A) {
            assertThrows([UInt8(op), 0x41, 0x00, 0x40], .invalidOpcode(offset: 0, byte: UInt8(op)))
        }
        for op in 0x65...0x9A {
            assertThrows([0x8A, UInt8(op), 0x40], .invalidOpcode(offset: 1, byte: UInt8(op)))
            XCTAssertThrowsError(try InstructionDecoder.expressionEnd(in: [0x41, 0x01, UInt8(op), 0x40], at: 0)) { e in
                XCTAssertEqual(e as? ScriptDecodeError, .invalidOpcode(offset: 2, byte: UInt8(op)))
            }
        }
        assertThrows([0xFF, 0x41, 0x00, 0x40], .nullBuiltin(offset: 0))      // null TVector (script-builtins.md)
        assertThrows([0x8A, 0xD9, 0xFF, 0x40, 0x40], .nullBuiltin(offset: 2))
        // Text, prompt, match and inline strings that never reach their terminator.
        assertThrows([0x41, 0x42], .textRunsPastEnd(offset: 0))
        assertThrows([0x00, 0x41, 0x42], at: 1, .textRunsPastEnd(offset: 1))
        assertThrows([0x8F, 0x2A, 0x79], .textRunsPastEnd(offset: 0))
        assertThrows([0x90, 0x79, 0x65, 0x73, 0x2C, 0x6E], .textRunsPastEnd(offset: 0))
        assertThrows([0x8A, 0x44, 0x61, 0x62], .textRunsPastEnd(offset: 1))
        // A 0x45 block or a fixed operand past the end.
        assertThrows([0x8A, 0x45, 0x00, 0x10, 0x01, 0x02, 0x40], .truncated(offset: 1))
        assertThrows([0x8A, 0x45, 0x00], .truncated(offset: 1))
        assertThrows([0x90, 0x6E, 0x6F, 0x00, 0x01], .truncated(offset: 0))
        assertThrows([0x89, 0x00, 0x40, 0x7F, 0xFF, 0x00, 0x10], .truncated(offset: 0))   // n × u16 > what is left
        assertThrows([0x88, 0x07], .truncated(offset: 0))
        assertThrows([0x8A, 0x41], .truncated(offset: 1))
        assertThrows([0x8A, 0x41, 0x01], .truncated(offset: 3))               // no 0x40
        assertThrows([], .truncated(offset: 0))
        assertThrows([0x00], at: 1, .truncated(offset: 1))
        assertThrows([0x00], at: -1, .truncated(offset: -1))

        // 0x1802 hostile sweep: at every offset the decoder returns or throws a ScriptDecodeError. For every offset
        // where a statement decodes, EVERY prefix length from offset + length down to offset is tried (one copy per
        // offset, shortened with popLast): the uncut prefix decodes to the same length (a text throws there too —
        // its terminator byte is cut), every shorter one throws a ScriptDecodeError. Prefixes shorter than `offset`
        // all take the same out-of-range path as the cut at `offset` itself (truncated(offset)). An offset inside a
        // text (offset − 1 decodes as a text with the same end) walks the same scan as that text's start, which
        // gets every cut; it is cut at its end, one byte short and at `offset` only (keeps the sweep cubic-free).
        let seg = try segment0x1802()
        var decoded = 0, cutsTried = 0
        var failures: [String] = []
        for offset in 0..<seg.count {
            _ = try? InstructionDecoder.expressionEnd(in: seg, at: offset)
            guard let i = try? InstructionDecoder.statement(in: seg, at: offset) else { continue }
            decoded += 1
            var prefix = Array(seg[0..<(offset + i.length)])
            let before = offset > 0 ? try? InstructionDecoder.statement(in: seg, at: offset - 1) : nil
            let insideText = i.mnemonic == "text" && before?.mnemonic == "text"
                && before.map { $0.offset + $0.length } == offset + i.length
            while prefix.count >= offset {
                if insideText && prefix.count < offset + i.length - 1 && prefix.count > offset {
                    prefix.removeLast(prefix.count - offset)
                    continue
                }
                cutsTried += 1
                let whole = prefix.count == offset + i.length && i.mnemonic != "text"
                do {
                    let j = try InstructionDecoder.statement(in: prefix, at: offset)
                    if !whole || j.length != i.length { failures.append("@\(offset) cut \(prefix.count) decoded") }
                } catch let e as ScriptDecodeError {
                    if whole { failures.append("@\(offset) cut \(prefix.count) threw \(e)") }
                    if prefix.count == offset && e != .truncated(offset: offset) {
                        failures.append("@\(offset) cut \(prefix.count): \(e)")
                    }
                } catch {
                    failures.append("@\(offset) cut \(prefix.count): \(error)")
                }
                if prefix.isEmpty { break }
                prefix.removeLast()
            }
        }
        XCTAssertEqual(failures, [], "\(failures.prefix(10))")
        XCTAssertGreaterThan(decoded, 0)
        XCTAssertGreaterThan(cutsTried, decoded)
    }
}
