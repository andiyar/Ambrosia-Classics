// DisasmRange.java — raw PPC listing of address ranges: args <out> start:end [start:end ...]
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.app.cmd.disassemble.DisassembleCommand;
import java.io.*;

public class DisasmRange extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        PrintWriter w = new PrintWriter(new FileWriter(a[0]));
        Listing lst = currentProgram.getListing();
        for (int i = 1; i < a.length; i++) {
            String[] p = a[i].split(":");
            Address s = toAddr(Long.parseLong(p[0], 16));
            Address e = toAddr(Long.parseLong(p[1], 16));
            w.printf("// ==== range %s-%s ====%n", s, e);
            Address cur = s;
            while (cur.compareTo(e) < 0) {
                Instruction ins = lst.getInstructionAt(cur);
                if (ins == null) {
                    DisassembleCommand cmd = new DisassembleCommand(cur, new AddressSet(cur, cur.add(3)), false);
                    cmd.applyTo(currentProgram);
                    ins = lst.getInstructionAt(cur);
                }
                if (ins == null) { w.printf("%s  ??%n", cur); cur = cur.add(4); continue; }
                Function f = getFunctionAt(cur);
                if (f != null) w.printf("// -- %s%n", f.getName());
                w.printf("%s  %s%n", ins.getAddress(), ins.toString());
                cur = cur.add(ins.getLength());
            }
        }
        w.close();
    }
}
