import Foundation

/// Malformed script bytecode. Every read is bounds-checked; nothing traps (plan Invariant 4).
/// What `offset` reports: `invalidOpcode` / `nullBuiltin` — the refused byte; `textRunsPastEnd` — the text
/// statement, 0x8F, 0x90 or 0x44 that started the string; `truncated` — for a cut operand, the opcode that owns
/// it (the statement for statement-level operands, the expression opcode for 0x41–0x49, 0x60–0x64, 0x45 and the
/// call forms' fixed bytes); for a missing next opcode — an expression's 0x40 or the statement byte itself — the
/// position where that byte should be, i.e. the end of the bytes (or the out-of-range `offset` asked for).
public enum ScriptDecodeError: Error, Equatable, Sendable {
    /// An opcode the tables mark invalid: statements 0x80, 0x94–0x9A; expressions 0x65–0x9A (script-vm.md §4,
    /// §8; the original raises its invalid-opcode error, `FUN_100bdef4`).
    case invalidOpcode(offset: Int, byte: UInt8)
    /// 0xFF, statement or expression: the original indexes the builtin table, finds the null TVector of entry 0xFF
    /// and calls through it (script-vm.md §8; script-builtins.md). Never shipped; refused by name.
    case nullBuiltin(offset: Int)
    /// An operand, a 0x45 block or an expression's 0x40 lies past the end of the bytes.
    case truncated(offset: Int)
    /// A literal text, a 0x8F prompt, a 0x90 word list or a 0x44 inline string reaches the end of the bytes
    /// without its terminator byte.
    case textRunsPastEnd(offset: Int)
}

/// Decodes one statement (`DoInterpAt__7TInterpFsP5VAddr @ 10080c98`) or measures one expression
/// (`DoExpr__7TInterpFRPUc @ 1007ddfc`) — script-vm.md §4, §5, §8, with `docs/cythera/tools/scriptdis.py` as the
/// oracle for the listing (`Dis.stmt`, `Dis.expr`, `Dis.callform`). It does not classify segments, walk
/// reachability or execute (C9, Phase 2).
public enum InstructionDecoder {

    /// The statement at `offset`.
    public static func statement(in bytes: [UInt8], at offset: Int) throws -> ScriptInstruction {
        var r = Reader(bytes: bytes, pc: offset)
        let op = try r.byte(for: offset)
        let row = ScriptOpcodes.statement(op)
        var mnemonic = row.mnemonic
        var targets: [Int] = []
        var refs: [ScriptReference] = []

        switch row.form {
        case .none:
            break
        case .text:
            // GetString: stops at 0 or ≥ 0x80 and leaves the pc ON that byte — which must exist (§8 first ⚑).
            r.pc = try terminator(in: bytes, from: offset, stopHigh: true, start: offset)
        case .frame:
            try r.skip(2, for: offset)
        case .slotExpr:
            let slot = try r.byte(for: offset)
            if slot < 0x40 { try skipExpressions(&r, 1, &refs) }  // ≥ 0x40: the slot byte only (§8)
        case .word16Expr:
            let word = try r.u16(for: offset)
            try skipExpressions(&r, 1, &refs)
            refs.append(.word(word))                             // `Dis.stmt` 0x83: after its expression
        case .threeExprs:
            try skipExpressions(&r, 3, &refs)
        case .seg16Off16Expr:
            try r.skip(4, for: offset); try skipExpressions(&r, 1, &refs)
        case .byteTwoExprs:
            try r.skip(1, for: offset); try skipExpressions(&r, 2, &refs)
        case .byteExpr:
            try r.skip(1, for: offset); try skipExpressions(&r, 1, &refs)
        case .target16:
            targets = [try r.u16(for: offset)]
        case .switchTable:
            try skipExpressions(&r, 1, &refs)
            let n = try r.u16(for: offset)
            guard n * 2 <= bytes.count - r.pc else { throw ScriptDecodeError.truncated(offset: offset) }
            targets.reserveCapacity(n)
            for _ in 0..<n { targets.append(try r.u16(for: offset)) }
        case .expr:
            try skipExpressions(&r, 1, &refs)
        case .exprTarget16:
            try skipExpressions(&r, 1, &refs)
            targets = [try r.u16(for: offset)]
        case .promptString:
            r.pc = try terminator(in: bytes, from: offset + 1, stopHigh: true, start: offset) + 1
        case .matchWords:
            var c: UInt8
            repeat {
                repeat {
                    guard r.pc < bytes.count else { throw ScriptDecodeError.textRunsPastEnd(offset: offset) }
                    c = bytes[r.pc]
                    r.pc += 1
                } while c != 0 && c != 0x2C && c < 0x80
            } while c == 0x2C
            targets = [try r.u16(for: offset)]
        case .routineArgs:
            let seg = try r.u16(for: offset)
            let first = r.pc
            try skipExpressions(&r, 1, &refs)
            // `scriptdis.py` lists `call` when seg ≠ 0xFFFF and the integer operand is one constant integer
            // (0x41, 0x42 or a tag-0 0x43, then 0x40); otherwise `callx` (computed seg + int, or seg 0xFFFF).
            if seg != 0xFFFF && isConstantInteger(bytes[first..<r.pc]) { mnemonic = "call" }
            try skipExpressions(&r, 1, &refs)
        case .classArgs, .sendArgs:
            try r.skip(1, for: offset); try skipExpressions(&r, 1, &refs)
        case .subroutineArgs:
            let sub = try r.u16(for: offset)
            try skipExpressions(&r, 1, &refs)
            refs.append(.subroutine(sub))                        // `Dis.callform` 0x9E: after its arguments
        case .callArgs:
            try r.skip(2, for: offset); try skipExpressions(&r, 1, &refs)
        case .builtinArgs:
            try skipExpressions(&r, 1, &refs)
        case .invalid, .end, .fixed, .inlineString, .inlineBlock:
            throw ScriptDecodeError.invalidOpcode(offset: offset, byte: op)
        case .nullBuiltin:
            throw ScriptDecodeError.nullBuiltin(offset: offset)
        }
        return ScriptInstruction(offset: offset, length: r.pc - offset, mnemonic: mnemonic,
                                 jumpTargets: targets, kind: .statement, references: refs)
    }

    /// The offset just past the 0x40 that ends the expression starting at `offset`.
    public static func expressionEnd(in bytes: [UInt8], at offset: Int) throws -> Int {
        var r = Reader(bytes: bytes, pc: offset)
        var refs: [ScriptReference] = []
        try skipExpressions(&r, 1, &refs)
        return r.pc
    }

    /// Skips `count` consecutive expressions, appending the references it passes in the order `Dis` meets them
    /// (C9: 0x43 code pointers, 0x45 blocks and 0x47 words where they stand; a 0x9E target after its argument
    /// expression). Nested call forms open their own
    /// expressions, each ended by its own 0x40 before the enclosing one continues, so a pending count replaces
    /// recursion (no stack depth from input); a 0x9E's target is emitted when the count falls back to its level.
    private static func skipExpressions(_ r: inout Reader, _ count: Int, _ refs: inout [ScriptReference]) throws {
        var pending = count
        var subroutines: [(level: Int, target: Int)] = []
        while pending > 0 {
            let at = r.pc
            let op = try r.byte(for: at)
            switch ScriptOpcodes.expression(op).form {
            case .end:
                pending -= 1
                while let last = subroutines.last, last.level == pending {
                    refs.append(.subroutine(last.target))
                    subroutines.removeLast()
                }
            case .fixed(let size):
                let operand = r.pc
                try r.skip(size - 1, for: at)
                let b = r.bytes
                if op == 0x43, b[operand] & 0x80 != 0 {
                    refs.append(.pointer(UInt32(b[operand]) << 24 | UInt32(b[operand + 1]) << 16
                                         | UInt32(b[operand + 2]) << 8 | UInt32(b[operand + 3])))
                } else if op == 0x47 {
                    refs.append(.word(Int(b[operand]) << 8 | Int(b[operand + 1])))
                }
            case .inlineString:
                r.pc = try terminator(in: r.bytes, from: r.pc, stopHigh: false, start: at) + 1
            case .inlineBlock:
                let length = try r.u16(for: at)
                let start = r.pc
                try r.skip(length, for: at)
                refs.append(.inlineBlock(start..<(start + length)))
            case .classArgs, .sendArgs:
                try r.skip(1, for: at); pending += 1
            case .subroutineArgs:
                subroutines.append((pending, try r.u16(for: at))); pending += 1
            case .callArgs:
                try r.skip(2, for: at); pending += 1
            case .routineArgs:
                try r.skip(2, for: at); pending += 2
            case .builtinArgs:
                pending += 1
            case .nullBuiltin:
                throw ScriptDecodeError.nullBuiltin(offset: at)
            default:
                throw ScriptDecodeError.invalidOpcode(offset: at, byte: op)
            }
        }
    }

    /// The index of the first byte at or after `from` that is 0 (or, with `stopHigh`, ≥ 0x80).
    private static func terminator(in bytes: [UInt8], from: Int, stopHigh: Bool, start: Int) throws -> Int {
        var e = max(from, 0)
        while e < bytes.count {
            let c = bytes[e]
            if c == 0 || (stopHigh && c >= 0x80) { return e }
            e += 1
        }
        throw ScriptDecodeError.textRunsPastEnd(offset: start)
    }

    /// One integer literal and the 0x40: `41 i8 40`, `42 i16 40`, or `43 u32 40` with a tag-0 value
    /// (`scriptdis.py` `callform`: one atom whose text is a decimal integer).
    private static func isConstantInteger(_ e: ArraySlice<UInt8>) -> Bool {
        guard let op = e.first else { return false }
        let b = e.startIndex
        switch (op, e.count) {
        case (0x41, 3), (0x42, 4): return true
        case (0x43, 6): return e[b + 1] & 0xF0 == 0
        default: return false
        }
    }

    /// A bounds-checked cursor.
    private struct Reader {
        let bytes: [UInt8]
        var pc: Int

        mutating func byte(for at: Int) throws -> UInt8 {
            guard pc >= 0, pc < bytes.count else { throw ScriptDecodeError.truncated(offset: at) }
            defer { pc += 1 }
            return bytes[pc]
        }

        mutating func u16(for at: Int) throws -> Int {
            guard pc >= 0, pc <= bytes.count - 2 else { throw ScriptDecodeError.truncated(offset: at) }
            defer { pc += 2 }
            return Int(bytes[pc]) << 8 | Int(bytes[pc + 1])
        }

        mutating func skip(_ n: Int, for at: Int) throws {
            guard n >= 0, pc >= 0, n <= bytes.count - pc else { throw ScriptDecodeError.truncated(offset: at) }
            pc += n
        }
    }
}
