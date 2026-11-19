// DumpData.java — every 4-byte word of a data range as Ghidra loaded it (after PEF unpacking and relocation),
// with its r2 (TOC) slot, its value, what that value points at, and the labels/data defined in the word:
// args <out> start:end
// Written for the Deimos OS X fragment (ghidra/regen-deimos-osx.sh); generic for any PEF program.
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.program.model.lang.Register;
import ghidra.program.model.mem.Memory;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.math.BigInteger;
import java.util.*;

public class DumpData extends GhidraScript {
    private Memory mem;
    private Listing lst;
    private SymbolTable st;

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        String[] p = a[1].split(":");
        Address s = toAddr(Long.parseLong(p[0], 16));
        Address e = toAddr(Long.parseLong(p[1], 16));
        mem = currentProgram.getMemory();
        lst = currentProgram.getListing();
        st = currentProgram.getSymbolTable();

        // r2 as the analysis recorded it at the first function entry (DumpSymbols shows it is one value throughout)
        Register r2reg = currentProgram.getRegister("r2");
        Function first = currentProgram.getFunctionManager().getFunctions(true).next();
        BigInteger r2v = currentProgram.getProgramContext().getValue(r2reg, first.getEntryPoint(), false);
        if (r2v == null) throw new IllegalStateException("no r2 value in the program context");
        long r2 = r2v.longValue();

        PrintWriter w = new PrintWriter(new BufferedWriter(new FileWriter(a[0])));
        w.printf("// program %s  data words %s-%s  r2 = %x%n", currentProgram.getName(), s, e, r2);
        w.printf("// One line per 4-byte word of the data section, as Ghidra loaded it (PEF unpacked, relocations applied).%n");
        w.printf("// Columns: address  r2-slot  value  ->target  | in-word%n");
        w.printf("//   r2-slot  the word's offset from r2 written as the listing writes it (lwz rX,-0x77a0(r2) -> -0x77a0(r2)),%n");
        w.printf("//            when the word is within a signed 16-bit displacement of r2; '.' otherwise%n");
        w.printf("//   value    the word, hex; '--------' in the uninitialized (zero-filled at load) part%n");
        w.printf("//   ->target what the value points at, when it is an address in the program: the function at it, else the%n");
        w.printf("//            primary symbol at it (imports, labels, Ghidra's default DAT_/s_/PTR_ names), else the containing%n");
        w.printf("//            function as name+0xoff, else the memory block it lies in as (block code|data|zero-filled);%n");
        w.printf("//            then ' tv->F' when the target word itself holds function F's entry%n");
        w.printf("//            (a transition vector); '-' when the value is not an address in the program%n");
        w.printf("//   in-word  symbols and defined data that start inside this word: +k:name (k = byte offset in the word,%n");
        w.printf("//            omitted for 0), data as [type] or [type \"string\"]; strings longer than 60 chars are cut with ...%n");
        w.printf("// In the uninitialized part only words that carry a symbol or defined data are listed.%n");

        int words = 0, slots = 0, uninit = 0;
        Address cur = s;
        while (cur.compareTo(e) < 0) {
            MemoryBlock b = mem.getBlock(cur);
            String inWord = inWord(cur);
            long off = cur.getOffset() - r2;
            String slot = (off >= -0x8000 && off <= 0x7fff)
                ? (off < 0 ? "-0x" + Long.toHexString(-off) : "0x" + Long.toHexString(off)) + "(r2)" : ".";
            if (b != null && b.isInitialized()) {
                long v = mem.getInt(cur) & 0xffffffffL;
                w.printf("%s %12s %08x %s%s%n", cur, slot, v, target(v), inWord.isEmpty() ? "" : " |" + inWord);
                words++;
                if (!slot.equals(".")) slots++;
            } else if (!inWord.isEmpty()) {
                w.printf("%s %12s -------- - |%s%n", cur, slot, inWord);
                uninit++;
            }
            cur = cur.add(4);
        }
        w.printf("// %d initialized words (%d of them r2 slots), %d labelled uninitialized words%n", words, slots, uninit);
        w.close();
        if (w.checkError()) throw new IOException("DumpData: write error on " + a[0]);
        println("DumpData: " + words + " initialized words, " + slots + " r2 slots, " + uninit + " labelled uninitialized words");
    }

    private String target(long v) {
        Address t;
        try { t = toAddr(v); } catch (Exception ex) { return "-"; }
        if (!mem.contains(t)) return "-";
        String name;
        Function f = getFunctionAt(t);
        if (f != null) name = f.getName(true);
        else {
            Symbol ps = st.getPrimarySymbol(t);
            if (ps != null) name = ps.getName(true);
            else {
                Function c = getFunctionContaining(t);
                if (c == null) {   // an address no symbol marks: say which kind of memory it lies in
                    MemoryBlock ub = mem.getBlock(t);
                    return "->(" + ub.getName() + (ub.isExecute() ? " code" : ub.isInitialized() ? " data" : " zero-filled") + ")";
                }
                name = c.getName(true) + "+0x" + Long.toHexString(t.subtract(c.getEntryPoint()));
            }
        }
        // transition vector: the target word holds a function entry
        MemoryBlock tb = mem.getBlock(t);
        if (tb != null && tb.isInitialized() && !tb.isExecute() && (v & 3) == 0) {
            try {
                Function tf = getFunctionAt(toAddr(mem.getInt(t) & 0xffffffffL));
                if (tf != null) name += " tv->" + tf.getName(true);
            } catch (Exception ex) { /* word straddles a block end: no tvec */ }
        }
        return "->" + name;
    }

    private String inWord(Address w0) {
        StringBuilder sb = new StringBuilder();
        for (int k = 0; k < 4; k++) {
            Address x = w0.add(k);
            String pre = k == 0 ? "" : "+" + k + ":";
            Symbol[] syms = st.getSymbols(x);
            List<String> names = new ArrayList<>();
            for (Symbol y : syms) names.add(y.getName(true));
            // primary first (Ghidra returns it first), the rest sorted for a stable order
            if (names.size() > 1) Collections.sort(names.subList(1, names.size()));
            for (String n : names) sb.append(' ').append(pre).append(n);
            Data d = lst.getDefinedDataAt(x);
            if (d != null) {
                sb.append(' ').append(pre).append('[').append(d.getDataType().getName());
                Object val = d.getValue();
                if (val instanceof String) sb.append(" \"").append(esc((String) val)).append('"');
                sb.append(']');
            }
        }
        return sb.toString();
    }

    private static String esc(String v) {
        StringBuilder sb = new StringBuilder();
        int n = 0;
        for (char c : v.toCharArray()) {
            if (n++ >= 60) { sb.append("..."); break; }
            if (c == '"' || c == '\\') sb.append('\\').append(c);
            else if (c >= 0x20 && c < 0x7f) sb.append(c);
            else if (c <= 0xff) sb.append(String.format("\\x%02x", (int) c));
            else sb.append(String.format("\\u%04x", (int) c));
        }
        return sb.toString();
    }
}
