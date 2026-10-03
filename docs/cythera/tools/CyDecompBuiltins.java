// Cythera 1.0.4 PPC: decompile the script-VM builtin opcodes 0xA0..0xFE.
// DoExpr/DoInterpAt index a TVector table at TOC+0x1FF0 = 0x100D7270 (r2 = 0x100D5280):
//   addi r8,r2,0x1ff0; lwzx r12,r8,(op-0xA0)*4; bl 0x100c50e8 (cross-TOC pointer-call glue).
// Each table word -> TVector {code, toc}; the code word is the builtin's entry. Most entries lie in
// the 0x10093E14..0x1009B164 gap that auto-analysis never turned into functions (no direct calls).
// This script reads the table from program memory (PEF relocations applied by the loader; falls
// back to section-relative arithmetic if not), creates a function per entry named Builtin_XX,
// pins r2 to the TOC over each body, and decompiles them into one file.
// args: <out.c>
// Run on a COPY of the analysed project (it modifies the program):
//   analyzeHeadless <projdir> Cythera_pef -process Cythera_pef -noanalysis \
//     -scriptPath docs/cythera/tools -postScript CyDecompBuiltins.java ghidra/Cythera_builtins.decompiled.c
import ghidra.app.script.GhidraScript;
import ghidra.app.decompiler.*;
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.program.model.address.*;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import ghidra.program.model.lang.Register;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.*;
import java.math.BigInteger;
import java.util.*;

public class CyDecompBuiltins extends GhidraScript {
    static final long TOC = 0x100D5280L, TABLE = 0x100D7270L, DATA = 0x100CD280L, CODE = 0x10000000L;

    long word(long a) throws Exception { return getInt(toAddr(a)) & 0xffffffffL; }

    public void run() throws Exception {
        String[] a = getScriptArgs();
        println("language: " + currentProgram.getLanguageID() + " cspec " + currentProgram.getCompilerSpec().getCompilerSpecID());
        List<long[]> t = new ArrayList<>();   // {opcode, entry}
        for (int i = 0; i < 0x60; i++) {
            long tv = word(TABLE + 4L * i);
            if (tv == 0) { println(String.format("op %02x: null", 0xA0 + i)); continue; }
            if (tv < CODE) tv += DATA;                 // unrelocated, section-relative
            long code = word(tv);
            if (code < CODE) code += CODE;
            if (code >= DATA) { println(String.format("op %02x: insane entry %08x (tv %08x)", 0xA0 + i, code, tv)); continue; }
            t.add(new long[]{0xA0 + i, code});
            println(String.format("op %02x -> TVector %08x -> code %08x", 0xA0 + i, tv, code));
        }
        FunctionManager fm = currentProgram.getFunctionManager();
        for (long[] e : t) {
            Address ad = toAddr(e[1]);
            String name = String.format("Builtin_%02X", e[0]);
            if (getInstructionAt(ad) == null) disassemble(ad);
            Function f = fm.getFunctionAt(ad);
            if (f == null) {
                Function cont = fm.getFunctionContaining(ad);
                if (cont != null) {
                    AddressSetView rest = new AddressSet(cont.getBody()).subtract(new AddressSet(ad, cont.getBody().getMaxAddress()));
                    try { cont.setBody(rest); } catch (Exception ex) { println("setBody fail " + cont.getName() + " " + ex); }
                }
                f = createFunction(ad, name);
                if (f == null) { println("create failed " + name); continue; }
            } else {
                // keep an existing (named) symbol but add the builtin label as a comment
                try { if (f.getName().startsWith("FUN_")) f.setName(name, SourceType.USER_DEFINED); } catch (Exception ex) {}
                f.setComment(name);
            }
        }
        for (long[] e : t) {
            Function f = fm.getFunctionAt(toAddr(e[1]));
            if (f != null) CreateFunctionCmd.fixupFunctionBody(currentProgram, f, monitor);
        }
        Register r2 = currentProgram.getRegister("r2");
        ProgramContext pc = currentProgram.getProgramContext();
        for (long[] e : t) {
            Function f = fm.getFunctionAt(toAddr(e[1]));
            if (f == null) continue;
            for (AddressRange rg : f.getBody().getAddressRanges())
                pc.setValue(r2, rg.getMinAddress(), rg.getMaxAddress(), BigInteger.valueOf(TOC));
        }
        DecompInterface d = new DecompInterface(); d.openProgram(currentProgram);
        PrintWriter w = new PrintWriter(new FileWriter(a[0]));
        int ok = 0;
        for (long[] e : t) {
            Address ad = toAddr(e[1]);
            Function f = fm.getFunctionAt(ad);
            w.printf("%n// ==== Builtin_%02X @ %08x (%s) ====%n", e[0], e[1], f == null ? "-" : f.getName());
            if (f == null) { w.println("// <no function>"); continue; }
            DecompileResults res = d.decompileFunction(f, 120, new ConsoleTaskMonitor());
            if (res != null && res.decompileCompleted()) { w.print(res.getDecompiledFunction().getC()); ok++; }
            else w.println("// <decompile failed: " + (res != null ? res.getErrorMessage() : "null") + ">");
        }
        w.close();
        println("CyDecompBuiltins: wrote " + ok + "/" + t.size());
    }
}
