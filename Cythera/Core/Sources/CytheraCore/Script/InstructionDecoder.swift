import Foundation

/// Malformed script bytecode. Every read is bounds-checked; nothing traps (plan Invariant 4).
/// `offset` is where the refused opcode sits (for a nested expression, the innermost opcode whose operands could
/// not be read; for a statement-level operand, the statement).
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
            if slot < 0x40 { try skipExpressions(&r, 1) }       // ≥ 0x40: the slot byte only (§8)
        case .word16Expr:
            try r.skip(2, for: offset); try skipExpressions(&r, 1)
        case .threeExprs:
            try skipExpressions(&r, 3)
        case .seg16Off16Expr:
            try r.skip(4, for: offset); try skipExpressions(&r, 1)
        case .byteTwoExprs:
            try r.skip(1, for: offset); try skipExpressions(&r, 2)
        case .byteExpr:
            try r.skip(1, for: offset); try skipExpressions(&r, 1)
        case .target16:
            targets = [try r.u16(for: offset)]
        case .switchTable:
            try skipExpressions(&r, 1)
            let n = try r.u16(for: offset)
            guard n * 2 <= bytes.count - r.pc else { throw ScriptDecodeError.truncated(offset: offset) }
            targets.reserveCapacity(n)
            for _ in 0..<n { targets.append(try r.u16(for: offset)) }
        case .expr:
            try skipExpressions(&r, 1)
        case .exprTarget16:
            try skipExpressions(&r, 1)
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
            try skipExpressions(&r, 1)
            // `scriptdis.py` lists `call` when seg ≠ 0xFFFF and the integer operand is one constant integer
            // (0x41, 0x42 or a tag-0 0x43, then 0x40); otherwise `callx` (computed seg + int, or seg 0xFFFF).
            if seg != 0xFFFF && isConstantInteger(bytes[first..<r.pc]) { mnemonic = "call" }
            try skipExpressions(&r, 1)
        case .classArgs, .sendArgs:
            try r.skip(1, for: offset); try skipExpressions(&r, 1)
        case .subroutineArgs, .callArgs:
            try r.skip(2, for: offset); try skipExpressions(&r, 1)
        case .builtinArgs:
            try skipExpressions(&r, 1)
        case .invalid, .end, .fixed, .inlineString, .inlineBlock:
            throw ScriptDecodeError.invalidOpcode(offset: offset, byte: op)
        case .nullBuiltin:
            throw ScriptDecodeError.nullBuiltin(offset: offset)
        }
        return ScriptInstruction(offset: offset, length: r.pc - offset, mnemonic: mnemonic,
                                 jumpTargets: targets, kind: .statement)
    }

    /// The offset just past the 0x40 that ends the expression starting at `offset`.
    public static func expressionEnd(in bytes: [UInt8], at offset: Int) throws -> Int {
        var r = Reader(bytes: bytes, pc: offset)
        try skipExpressions(&r, 1)
        return r.pc
    }

    /// Skips `count` consecutive expressions. Nested call forms open their own expressions, each ended by its own
    /// 0x40 before the enclosing one continues, so a pending count replaces recursion (no stack depth from input).
    private static func skipExpressions(_ r: inout Reader, _ count: Int) throws {
        var pending = count
        while pending > 0 {
            let at = r.pc
            let op = try r.byte(for: at)
            switch ScriptOpcodes.expression(op).form {
            case .end:
                pending -= 1
            case .fixed(let size):
                try r.skip(size - 1, for: at)
            case .inlineString:
                r.pc = try terminator(in: r.bytes, from: r.pc, stopHigh: false, start: at) + 1
            case .inlineBlock:
                let length = try r.u16(for: at)
                try r.skip(length, for: at)
            case .classArgs, .sendArgs:
                try r.skip(1, for: at); pending += 1
            case .subroutineArgs, .callArgs:
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
