// StringXrefs.java — Ghidra headless postScript for the Deimos Rising PEF (stripped).
// For every instruction in every function, follows each memory reference (and one level of
// TOC indirection: a 4-byte pointer stored at the referenced address) and, when the target is a
// printable C string (>=4 chars), prints:  <func>\t<funcaddr>\t<insnaddr>\t<straddr>\t<string>
// Also prints every CALL target name per function as:  CALL\t<func>\t<callee>
// Usage: analyzeHeadless <projdir> Deimos_pef -process Deimos_pef -noanalysis -readOnly \
//          -scriptPath docs/deimos/tools -postScript StringXrefs.java <outpath>
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.program.model.mem.*;
import ghidra.program.model.symbol.*;
import java.io.*;

public class StringXrefs extends GhidraScript {
    Memory mem;
    String cstr(Address a) {
        try {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < 300; i++) {
                int b = mem.getByte(a.add(i)) & 0xff;
                if (b == 0) break;
                if (b == 13 || b == 10) { sb.append("\\n"); continue; }
                if (b < 32 || b > 126) return null;
                sb.append((char) b);
            }
            return sb.length() >= 4 ? sb.toString() : null;
        } catch (Exception e) { return null; }
    }
    @Override
    public void run() throws Exception {
        String out = getScriptArgs().length > 0 ? getScriptArgs()[0] : "/tmp/xrefs.tsv";
        PrintWriter w = new PrintWriter(new FileWriter(out));
        mem = currentProgram.getMemory();
        Listing lst = currentProgram.getListing();
        for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
            for (Instruction ins : lst.getInstructions(f.getBody(), true)) {
                for (Reference r : ins.getReferencesFrom()) {
                    Address t = r.getToAddress();
                    if (r.getReferenceType().isCall()) {
                        Function c = getFunctionAt(t);
                        w.printf("CALL\t%s\t%s\t%s%n", f.getName(), f.getEntryPoint(), c != null ? c.getName() : t.toString());
                        continue;
                    }
                    if (!t.isMemoryAddress()) continue;
                    String s = cstr(t);
                    Address sa = t;
                    if (s == null) {
                        try {
                            int p = mem.getInt(t);
                            Address pa = t.getNewAddress(p & 0xffffffffL);
                            if (mem.contains(pa)) { s = cstr(pa); sa = pa; }
                        } catch (Exception e) { }
                    }
                    if (s != null)
                        w.printf("STR\t%s\t%s\t%s\t%s\t%s%n", f.getName(), f.getEntryPoint(), ins.getAddress(), sa, s);
                }
            }
        }
        w.close();
        println("StringXrefs: wrote " + out);
    }
}
