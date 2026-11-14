import Foundation

/// One decoded script instruction, as one line of the `scriptdis.py` listing (plan S2; Task C8 adds
/// `jumpTargets` and `kind`, C9 `references`). Offsets are in the decrypted segment.
public struct ScriptInstruction: Equatable, Sendable {
    /// The listing's flag column: ` ` reached, `>` jump target, `x` dead code (found only by the gap sweep).
    public enum Flag: Equatable, Sendable {
        case reached
        case jumpTarget
        case dead
    }

    /// `.statement` = decoded as `DoInterpAt` runs it (every instruction `InstructionDecoder.statement` returns);
    /// `.expressionOnly` = a value-producing form that only `DoExpr` runs (script-vm.md §5: e.g. the 0x9B class-0
    /// `id_of` path, §8). The decoder of this task produces statements only. `.literal` (C9) = a listing line
    /// that is not code: a literal block, undecoded bytes, a data line or a combat-AI `name`/`entry` line.
    public enum Kind: Equatable, Sendable {
        case statement
        case expressionOnly
        case literal
    }

    /// Where the instruction starts.
    public let offset: Int
    /// Its size in bytes, operands included. A literal text's length stops BEFORE its terminator (§8 first ⚑).
    public let length: Int
    /// The listing's token: `text`, `frame`, `set`, …, `builtin` (the builtin's name is operand text, not this).
    public let mnemonic: String
    /// Set by the segment walk (C9); the decoder reports `.reached`.
    public var flag: Flag
    /// Jump targets only, absolute offsets in the segment (script-vm.md §8 "all branch operands are absolute"):
    /// 0x88, 0x89's table in order, 0x8C, 0x8D, 0x90 — the jumps that give the listing its `>` marks. The 0x9E
    /// local-subroutine target is NOT here (it gives no `>`): see `references` / `subroutineTargets`. Not
    /// range-checked: a target past the end is the walk's anomaly, not a decode error.
    public let jumpTargets: [Int]
    public let kind: Kind
    /// The operands the segment walk follows besides the jumps (C9), in the order `scriptdis.py`'s `Dis` meets
    /// them (`Dis.expr`, `Dis.callform`, `Dis.stmt`): mostly byte order, but a 0x9E target comes after its
    /// argument expression and a 0x83 word after its value expression.
    public let references: [ScriptReference]

    /// The 0x9E local-subroutine targets (absolute offsets in the segment), statement or expression form.
    public var subroutineTargets: [Int] {
        references.compactMap { if case .subroutine(let t) = $0 { return t } else { return nil } }
    }

    public init(offset: Int, length: Int, mnemonic: String, flag: Flag = .reached, jumpTargets: [Int] = [],
                kind: Kind = .statement, references: [ScriptReference] = []) {
        self.offset = offset
        self.length = length
        self.mnemonic = mnemonic
        self.flag = flag
        self.jumpTargets = jumpTargets
        self.kind = kind
        self.references = references
    }
}

/// An operand that points somewhere in the segment, other than a jump (C9; `scriptdis.py` follows each).
public enum ScriptReference: Equatable, Sendable {
    /// 0x9E callsub: the absolute offset of a local subroutine (recorded after its argument expression).
    case subroutine(Int)
    /// 0x43 with bit 31 set: a code pointer VAddr (seg = bits 16–30, offset = low 16 bits), as stored. The walk
    /// follows it only when seg is the segment being listed (`Dis.vaddr` → `Dis.target`).
    case pointer(UInt32)
    /// 0x45: the inline literal block's bytes (after its u16 length).
    case inlineBlock(Range<Int>)
    /// 0x47 (expression) or 0x83 (statement, recorded after its expression): a segment word offset.
    case word(Int)
}
