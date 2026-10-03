// DisasmFuncs.java — Ghidra headless postScript: raw PPC disassembly of named functions.
// Usage: ... -postScript DisasmFuncs.java <outpath> FUN_1000abcd [FUN_... ...]
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import java.io.*;

public class DisasmFuncs extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        PrintWriter w = new PrintWriter(new FileWriter(a[0]));
        Listing lst = currentProgram.getListing();
        for (int i = 1; i < a.length; i++) {
            for (Function f : currentProgram.getFunctionManager().getFunctions(true)) {
                if (!f.getName().equals(a[i])) continue;
                w.printf("// ==== %s @ %s ====%n", f.getName(), f.getEntryPoint());
                for (Instruction ins : lst.getInstructions(f.getBody(), true))
                    w.printf("%s  %s%n", ins.getAddress(), ins.toString());
            }
        }
        w.close();
    }
}
