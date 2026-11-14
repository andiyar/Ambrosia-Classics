import Foundation

/// One decoded script instruction, as one line of the `scriptdis.py` listing (plan S2; Task C8 adds
/// `jumpTargets` and `kind`). Offsets are in the decrypted segment.
public struct ScriptInstruction: Equatable, Sendable {
    /// The listing's flag column: ` ` reached, `>` jump target, `x` dead code (found only by the gap sweep).
    public enum Flag: Equatable, Sendable {
        case reached
        case jumpTarget
        case dead
    }

    /// `.statement` = decoded as `DoInterpAt` runs it (every instruction `InstructionDecoder.statement` returns);
    /// `.expressionOnly` = a value-producing form that only `DoExpr` runs (script-vm.md §5: e.g. the 0x9B class-0
    /// `id_of` path, §8). The decoder of this task produces statements only.
    public enum Kind: Equatable, Sendable {
        case statement
        case expressionOnly
    }

    /// Where the instruction starts.
    public let offset: Int
    /// Its size in bytes, operands included. A literal text's length stops BEFORE its terminator (§8 first ⚑).
    public let length: Int
    /// The listing's token: `text`, `frame`, `set`, …, `builtin` (the builtin's name is operand text, not this).
    public let mnemonic: String
    /// Set by the segment walk (C9); the decoder reports `.reached`.
    public var flag: Flag
    /// Branch targets, absolute offsets in the segment (script-vm.md §8 "all branch operands are absolute"): 0x88,
    /// 0x89's table in order, 0x8C, 0x8D, 0x90 — the jumps that make a listing `>` label. 0x9E's subroutine target
    /// is a call, not a jump, and is not listed here. Not range-checked: a target past the end is the walk's
    /// anomaly, not a decode error.
    public let jumpTargets: [Int]
    public let kind: Kind

    public init(offset: Int, length: Int, mnemonic: String, flag: Flag = .reached, jumpTargets: [Int] = [],
                kind: Kind = .statement) {
        self.offset = offset
        self.length = length
        self.mnemonic = mnemonic
        self.flag = flag
        self.jumpTargets = jumpTargets
        self.kind = kind
    }
}
