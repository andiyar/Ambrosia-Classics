// args: <out.txt> <hexstart:hexend> ...   dumps listing instructions in each range
import ghidra.app.script.GhidraScript;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import java.io.*;
public class FzDisasm extends GhidraScript {
    public void run() throws Exception {
        String[] a = getScriptArgs();
        PrintWriter w = new PrintWriter(new FileWriter(a[0]));
        for (int i = 1; i < a.length; i++) {
            String[] p = a[i].split(":");
            Address s = toAddr(Long.parseLong(p[0],16)), e = toAddr(Long.parseLong(p[1],16));
            w.printf("%n;; ==== %s..%s ====%n", p[0], p[1]);
            Address cur = s;
            while (cur.compareTo(e) < 0) {
                Instruction ins = getInstructionAt(cur);
                if (ins == null) { disassemble(cur); ins = getInstructionAt(cur); }
                if (ins == null) { w.printf("%s  .word 0x%08x%n", cur, getInt(cur)); cur = cur.add(4); continue; }
                w.printf("%s  %s%n", cur, ins.toString());
                cur = cur.add(ins.getLength());
            }
        }
        w.close();
    }
}
