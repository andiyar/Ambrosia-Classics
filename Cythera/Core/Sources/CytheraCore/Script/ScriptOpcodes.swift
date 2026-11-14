import Foundation

/// How an opcode's operands are laid out after the opcode byte (script-vm.md §4, §5, §8; the walk of
/// `docs/cythera/tools/scriptdis.py` `Dis.stmt` / `Dis.expr` / `Dis.callform`). "expr" = one RPN expression
/// ended by its own 0x40; nested calls inside it end at their own 0x40 first.
public enum ScriptOperandForm: Equatable, Sendable {
    // Statement forms (`DoInterpAt @ 10080c98`).
    /// No operands (0x00 no-op, 0x8E input, 0x91 no-op).
    case none
    /// 0x01–0x7F: the opcode is the first character; the text runs to the first byte that is 0 or ≥ 0x80 and
    /// the pc is left ON that byte, which then executes (`GetString @ 10082fb0`; script-vm.md §8 first ⚑).
    case text
    /// 0x81 nArgs nLocals.
    case frame
    /// 0x82 slot + expr; a slot byte ≥ 0x40 consumes only the slot byte (§8).
    case slotExpr
    /// 0x83 u16 off + expr.
    case word16Expr
    /// 0x84 list, index, value: three exprs.
    case threeExprs
    /// 0x85 u16 seg, u16 off + expr.
    case seg16Off16Expr
    /// 0x86 field byte + obj expr + value expr.
    case byteTwoExprs
    /// 0x87 global byte + expr; 0x92 code byte + expr.
    case byteExpr
    /// 0x88 u16 absolute target (§8 third ⚑).
    case target16
    /// 0x89 expr + u16 n + n × u16 absolute targets; out of range falls through past the table.
    case switchTable
    /// 0x8A print, 0x8B return, 0x93 release: one expr.
    case expr
    /// 0x8C / 0x8D expr + u16 absolute target.
    case exprTarget16
    /// 0x8F: the string read like text (stops at 0 or ≥ 0x80), then the terminator byte is skipped (§8 second ⚑).
    case promptString
    /// 0x90: comma-separated words, each ended by 0, ',' or a byte ≥ 0x80 (the terminator is consumed), repeated
    /// while the terminator is ','; then u16 absolute target (DoInterpAt's 0x90 loop; `Dis.stmt`).
    case matchWords
    // Call forms, shared by statements and expressions (`Dis.callform`).
    /// 0x9B cls8 + one arg expr.
    case classArgs
    /// 0x9C seg16 + one expr + one arg expr. For seg ≠ 0xFFFF the first expr is the integer added to seg; for
    /// seg = 0xFFFF it is the computed target. Both encodings carry TWO expressions (script-vm.md §4 ⚑, §8 "call
    /// encodings"; DoInterpAt: each branch runs `DoExpr` twice). Invariant 8: listed as stored, never "fixed".
    case routineArgs
    /// 0x9D sel8 + one expr (receiver first, then the args).
    case sendArgs
    /// 0x9E u16 absolute offset + one arg expr.
    case subroutineArgs
    /// 0x9F u16 seg + one arg expr.
    case callArgs
    /// 0xA0–0xFE: one arg expr (script-vm.md §6 calling convention).
    case builtinArgs
    // Expression forms (`DoExpr @ 1007ddfc`).
    /// 0x40: end of expression.
    case end
    /// A fixed size in bytes INCLUDING the opcode.
    case fixed(Int)
    /// 0x44: inline C string to NUL, NUL consumed; bytes ≥ 0x80 allowed (`FUN_100b6ce8`, §8 second ⚑).
    case inlineString
    /// 0x45: u16 length + that many literal bytes.
    case inlineBlock
    // Refusals.
    /// The tables' invalid-opcode error (statements 0x80, 0x94–0x9A; expressions 0x65–0x9A).
    case invalid
    /// 0xFF: not an error in the original — it indexes the builtin table, whose 0xFF entry is null, and calls
    /// through a null TVector (script-vm.md §8; script-builtins.md). Refused by name.
    case nullBuiltin
}

/// One row of an opcode table.
public struct ScriptOpcodeRow: Equatable, Sendable {
    public let opcode: UInt8
    /// Statements: the listing's mnemonic (`scriptdis.py` `STMT_NAMES`, `text`, `builtin`); 0x9C is listed `callx`
    /// unless its integer operand is a constant (then `call`, decided per instruction). Expressions: a short name.
    public let mnemonic: String
    public let form: ScriptOperandForm
}

/// The statement table (script-vm.md §4, rows 0x00–0xFF) and the expression table (§5, rows 0x00–0xFF), as
/// `DoInterpAt` and `DoExpr` dispatch them.
public enum ScriptOpcodes {
    public static func statement(_ op: UInt8) -> ScriptOpcodeRow { statementTable[Int(op)] }
    public static func expression(_ op: UInt8) -> ScriptOpcodeRow { expressionTable[Int(op)] }

    /// Mnemonics of the statement rows 0x81–0x9F that are valid (`scriptdis.py` `STMT_NAMES`).
    static let statementRows: [UInt8: (String, ScriptOperandForm)] = [
        0x81: ("frame", .frame), 0x82: ("set", .slotExpr), 0x83: ("store", .word16Expr),
        0x84: ("atput", .threeExprs), 0x85: ("gstore", .seg16Off16Expr), 0x86: ("setfield", .byteTwoExprs),
        0x87: ("setglobal", .byteExpr), 0x88: ("goto", .target16), 0x89: ("switch", .switchTable),
        0x8A: ("print", .expr), 0x8B: ("return", .expr), 0x8C: ("jt", .exprTarget16),
        0x8D: ("jf", .exprTarget16), 0x8E: ("input", .none), 0x8F: ("prompt", .promptString),
        0x90: ("match", .matchWords), 0x91: ("nop91", .none), 0x92: ("raise", .byteExpr),
        0x93: ("release", .expr), 0x9B: ("sysnew", .classArgs), 0x9C: ("callx", .routineArgs),
        0x9D: ("send", .sendArgs), 0x9E: ("callsub", .subroutineArgs), 0x9F: ("call", .callArgs),
    ]

    static let statementTable: [ScriptOpcodeRow] = (0...0xFF).map { n in
        let op = UInt8(n)
        switch n {
        case 0x00: return ScriptOpcodeRow(opcode: op, mnemonic: "nop", form: .none)
        case 0x01...0x7F: return ScriptOpcodeRow(opcode: op, mnemonic: "text", form: .text)
        case 0xA0...0xFE: return ScriptOpcodeRow(opcode: op, mnemonic: "builtin", form: .builtinArgs)
        case 0xFF: return ScriptOpcodeRow(opcode: op, mnemonic: "invalid", form: .nullBuiltin)
        default:
            if let (mnemonic, form) = statementRows[op] {
                return ScriptOpcodeRow(opcode: op, mnemonic: mnemonic, form: form)
            }
            return ScriptOpcodeRow(opcode: op, mnemonic: "invalid", form: .invalid)   // 0x80, 0x94–0x9A
        }
    }

    /// Expression rows 0x40–0x64 (script-vm.md §5).
    static let expressionRows: [UInt8: (String, ScriptOperandForm)] = [
        0x40: ("end", .end), 0x41: ("i8", .fixed(2)), 0x42: ("i16", .fixed(3)), 0x43: ("u32", .fixed(5)),
        0x44: ("cstring", .inlineString), 0x45: ("block", .inlineBlock), 0x46: ("index", .fixed(1)),
        0x47: ("segword", .fixed(3)), 0x48: ("global", .fixed(2)), 0x49: ("farword", .fixed(5)),
        0x4A: ("+", .fixed(1)), 0x4B: ("-", .fixed(1)), 0x4C: ("*", .fixed(1)), 0x4D: ("/", .fixed(1)),
        0x4E: ("%", .fixed(1)), 0x4F: ("<", .fixed(1)), 0x50: ("<=", .fixed(1)), 0x51: (">", .fixed(1)),
        0x52: (">=", .fixed(1)), 0x53: ("!=", .fixed(1)), 0x54: ("==", .fixed(1)), 0x55: ("neg", .fixed(1)),
        0x56: ("&", .fixed(1)), 0x57: ("|", .fixed(1)), 0x58: ("^", .fixed(1)), 0x59: ("~", .fixed(1)),
        0x5A: ("<<", .fixed(1)), 0x5B: (">>", .fixed(1)), 0x5C: ("&&", .fixed(1)), 0x5D: ("||", .fixed(1)),
        0x5E: ("!", .fixed(1)), 0x5F: ("len", .fixed(1)), 0x60: ("has", .fixed(2)), 0x61: ("prop", .fixed(3)),
        0x62: ("field", .fixed(2)), 0x63: ("as", .fixed(2)), 0x64: ("is", .fixed(2)),
    ]

    static let expressionTable: [ScriptOpcodeRow] = (0...0xFF).map { n in
        let op = UInt8(n)
        switch n {
        case 0x00...0x2F: return ScriptOpcodeRow(opcode: op, mnemonic: "local", form: .fixed(1))
        case 0x30...0x3F: return ScriptOpcodeRow(opcode: op, mnemonic: "arg", form: .fixed(1))
        case 0x40...0x64:
            let (m, f) = expressionRows[op] ?? ("invalid", .invalid)
            return ScriptOpcodeRow(opcode: op, mnemonic: m, form: f)
        case 0x9B...0x9F:
            let (m, f) = statementRows[op] ?? ("invalid", .invalid)   // as the statements, result left on the stack
            return ScriptOpcodeRow(opcode: op, mnemonic: m, form: f)
        case 0xA0...0xFE: return ScriptOpcodeRow(opcode: op, mnemonic: "builtin", form: .builtinArgs)
        case 0xFF: return ScriptOpcodeRow(opcode: op, mnemonic: "invalid", form: .nullBuiltin)
        default: return ScriptOpcodeRow(opcode: op, mnemonic: "invalid", form: .invalid)   // 0x65–0x9A
        }
    }
}
