// Create functions at TVector targets missing from the main dump, then decompile them.
// args: <targets.txt: "hexaddr name" per line> <out.c>
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.*;
import java.math.BigInteger;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.ProgramContext;
import java.util.*;

public class FzDecompTargets extends GhidraScript {
    public void run() throws Exception {
        String[] a = getScriptArgs();
        println("language: " + currentProgram.getLanguageID() + " cspec " + currentProgram.getCompilerSpec().getCompilerSpecID());
        List<String[]> t = new ArrayList<>();
        BufferedReader r = new BufferedReader(new FileReader(a[0]));
        String line; while ((line = r.readLine()) != null) { line=line.trim(); if (line.isEmpty()) continue; t.add(line.split("\\s+")); }
        FunctionManager fm = currentProgram.getFunctionManager();
        // pass 1: disassemble + create
        for (String[] e : t) {
            Address ad = toAddr(Long.parseLong(e[0],16));
            if (getInstructionAt(ad) == null) disassemble(ad);
            Function f = fm.getFunctionAt(ad);
            if (f == null) {
                Function cont = fm.getFunctionContaining(ad);
                if (cont != null) {
                    // shrink the container so the new entry can exist
                    AddressSet body = new AddressSet(cont.getBody());
                    AddressSetView rest = body.subtract(new AddressSet(ad, cont.getBody().getMaxAddress()));
                    try { cont.setBody(rest); } catch (Exception ex) { println("setBody fail " + cont.getName() + " " + ex); }
                }
                f = createFunction(ad, e[1]);
                if (f == null) { println("create failed " + e[0]); continue; }
            } else {
                try { f.setName(e[1], SourceType.USER_DEFINED); } catch (Exception ex) {}
            }
        }
        // pass 2: re-fixup bodies of all new functions
        for (String[] e : t) {
            Address ad = toAddr(Long.parseLong(e[0],16));
            Function f = fm.getFunctionAt(ad);
            if (f != null) CreateFunctionCmd.fixupFunctionBody(currentProgram, f, monitor);
        }
        Register r2 = currentProgram.getRegister("r2");
        ProgramContext pc = currentProgram.getProgramContext();
        for (String[] e : t) {
            Function f = fm.getFunctionAt(toAddr(Long.parseLong(e[0],16)));
            if (f == null) continue;
            AddressSetView body = f.getBody();
            for (AddressRange rg : body.getAddressRanges()) pc.setValue(r2, rg.getMinAddress(), rg.getMaxAddress(), BigInteger.valueOf(0x100a7840L));
        }
        DecompInterface d = new DecompInterface(); d.openProgram(currentProgram);
        PrintWriter w = new PrintWriter(new FileWriter(a[1]));
        int ok = 0;
        for (String[] e : t) {
            Address ad = toAddr(Long.parseLong(e[0],16));
            Function f = fm.getFunctionAt(ad);
            w.printf("%n// ==== %s @ %s ====%n", e[1], e[0]);
            if (f == null) { w.println("// <no function>"); continue; }
            DecompileResults res = d.decompileFunction(f, 120, new ConsoleTaskMonitor());
            if (res != null && res.decompileCompleted()) { w.print(res.getDecompiledFunction().getC()); ok++; }
            else w.println("// <decompile failed: " + (res!=null?res.getErrorMessage():"null") + ">");
        }
        w.close();
        println("FzDecompTargets: wrote " + ok + "/" + t.size());
    }
}
