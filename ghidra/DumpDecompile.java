// DumpDecompile.java — Ghidra headless postScript (Java; no Jython/PyGhidra needed).
// Decompiles every function in the current program to one annotated C file.
// Usage (via analyzeHeadless): -postScript DumpDecompile.java <outpath>
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.listing.Function;
import ghidra.program.model.listing.FunctionManager;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.PrintWriter;
import java.io.FileWriter;

public class DumpDecompile extends GhidraScript {
    @Override
    public void run() throws Exception {
        String[] args = getScriptArgs();
        String outpath = (args.length > 0) ? args[0] : "/tmp/decompile_all.c";

        DecompInterface decomp = new DecompInterface();
        decomp.openProgram(currentProgram);
        ConsoleTaskMonitor monitor = new ConsoleTaskMonitor();
        FunctionManager fm = currentProgram.getFunctionManager();
        int total = fm.getFunctionCount();

        PrintWriter w = new PrintWriter(new FileWriter(outpath));
        w.printf("// Decompilation of %s (%d functions)%n", currentProgram.getName(), total);
        int i = 0, ok = 0;
        for (Function fn : fm.getFunctions(true)) {  // true = forward address order
            DecompileResults res = decomp.decompileFunction(fn, 60, monitor);
            String code;
            if (res != null && res.decompileCompleted()) {
                code = res.getDecompiledFunction().getC();
                ok++;
            } else {
                code = "// <decompile failed: " + (res != null ? res.getErrorMessage() : "null") + ">\n";
            }
            w.printf("%n// ==== %s @ %s ====%n", fn.getName(), fn.getEntryPoint().toString());
            w.print(code);
            if (i % 500 == 0) println("decompiled " + i + "/" + total);
            i++;
        }
        w.close();
        println("DumpDecompile: wrote " + ok + "/" + total + " functions to " + outpath);
    }
}
