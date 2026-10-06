// CyDecompAt.java — Ghidra headless postScript: decompile functions at given addresses, creating
// them first when auto-analysis made none (Cythera 1.0.4 PEF; generalises the 2026-10-03 scratch
// CySched.java `dec:` command). For bodies the main dump (ghidra/Cythera_pef.decompiled.c) lacks:
// TActiveMonster::DoMove 0x1004B8E8, Die 0x100469C0, the TStream reader/writer, KeyRoutine …
//
// Per address: disassemble if needed; if a function already starts there, use it; else, if the
// address lies inside another function's body (Ghidra merged it, e.g. KeyRoutine into
// ShowTileAnimate), cut that body back to end before the address; create the function (named from
// the spec, else CY_<addr>), fix up its body, pin r2 = the TOC 0x100D5280 over the body (as
// CyDecompBuiltins.java does), decompile (180 s timeout). Output uses DumpDecompile.java's
// separators, `// ==== <name> @ <addr> ====`, so ghidra/find_func.py works on it, then one line
// `// CyDecompAt: <created|existing|renamed>, body <min>-<max>`.
//
// Specs (script args after <out.c>, or — when there are none — the env var CYDECOMP_ADDRS,
// whitespace/comma separated):  ADDR | ADDR=NAME | @FILE.  FILE lines: `ADDR [LEN] [NAME]`
// (tb.py output works as-is), `#` starts a comment. ADDR is hex, `0x` optional.
//
// Recipe (Ghidra 12.1.3; the project path must have no dot-prefixed element, so not inside
// .claude/worktrees). Use the analysed project from `ghidra/decompile.sh Cythera_pef -processor
// PowerPC:BE:32:default -cspec macosx` (GHIDRA_PROJ=/tmp/ghidra-proj-cythera) — copy it and run
// -readOnly so the creations are not saved and the run repeats exactly:
//   cp -R /tmp/ghidra-proj-cythera "$P"            # $P: e.g. your scratchpad dir
//   /opt/homebrew/Cellar/ghidra/12.1.3/libexec/support/analyzeHeadless "$P" Cythera_pef \
//     -process Cythera_pef -noanalysis -readOnly -scriptPath docs/cythera/tools \
//     -postScript CyDecompAt.java "$PWD/ghidra/Cythera_extra.decompiled.c" \
//       @"$PWD/docs/cythera/tools/extra-addrs.txt" > ghidra/analyze-Cythera_extra.log 2>&1
//   grep 'CyDecompAt: wrote' ghidra/analyze-Cythera_extra.log
// Specs are processed in order; a later spec inside an earlier created body splits it again.
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.app.cmd.function.CreateFunctionCmd;
import ghidra.app.decompiler.DecompInterface;
import ghidra.app.decompiler.DecompileResults;
import ghidra.program.model.address.*;
import ghidra.program.model.lang.Register;
import ghidra.program.model.listing.*;
import ghidra.program.model.symbol.SourceType;
import ghidra.util.task.ConsoleTaskMonitor;
import java.io.*;
import java.math.BigInteger;
import java.nio.file.*;
import java.util.*;

public class CyDecompAt extends GhidraScript {
    static final long TOC = 0x100D5280L;

    static final class Spec { long addr; String name; Spec(long a, String n) { addr = a; name = n; } }

    static long hex(String s) {
        s = s.trim().toLowerCase();
        if (s.startsWith("0x")) s = s.substring(2);
        return Long.parseLong(s, 16);
    }

    static boolean isHex(String s) { return s.matches("(0x)?[0-9a-fA-F]+"); }

    void addSpec(List<Spec> out, String s) throws IOException {
        s = s.trim();
        if (s.isEmpty()) return;
        if (s.startsWith("@")) {
            for (String line : Files.readAllLines(Paths.get(s.substring(1)))) {
                int h = line.indexOf('#');
                if (h >= 0) line = line.substring(0, h);
                String[] t = line.trim().split("\\s+");
                if (t.length == 0 || t[0].isEmpty()) continue;
                String name = null;
                if (t.length >= 3) name = t[2];
                else if (t.length == 2 && !isHex(t[1])) name = t[1];
                out.add(new Spec(hex(t[0]), name));
            }
            return;
        }
        int eq = s.indexOf('=');
        if (eq >= 0) out.add(new Spec(hex(s.substring(0, eq)), s.substring(eq + 1)));
        else out.add(new Spec(hex(s), null));
    }

    void pin(Function f) throws Exception {
        Register r2 = currentProgram.getRegister("r2");
        ProgramContext pc = currentProgram.getProgramContext();
        for (AddressRange rg : f.getBody().getAddressRanges())
            pc.setValue(r2, rg.getMinAddress(), rg.getMaxAddress(), BigInteger.valueOf(TOC));
    }

    @Override
    public void run() throws Exception {
        String[] a = getScriptArgs();
        if (a.length < 1) { printerr("usage: CyDecompAt.java <out.c> [ADDR|ADDR=NAME|@FILE]..."); return; }
        List<Spec> specs = new ArrayList<>();
        for (int i = 1; i < a.length; i++) addSpec(specs, a[i]);
        if (specs.isEmpty()) {
            String env = System.getenv("CYDECOMP_ADDRS");
            if (env != null) for (String s : env.split("[\\s,]+")) addSpec(specs, s);
        }
        if (specs.isEmpty()) { printerr("CyDecompAt: no addresses (args or CYDECOMP_ADDRS)"); return; }

        FunctionManager fm = currentProgram.getFunctionManager();
        DecompInterface d = new DecompInterface();
        d.openProgram(currentProgram);
        ConsoleTaskMonitor mon = new ConsoleTaskMonitor();
        PrintWriter w = new PrintWriter(new FileWriter(a[0]));
        w.printf("// CyDecompAt of %s (%d addresses)%n", currentProgram.getName(), specs.size());
        int ok = 0;
        List<String> failed = new ArrayList<>();
        for (Spec sp : specs) {
            Address ad = toAddr(sp.addr);
            String how = "existing";
            if (getInstructionAt(ad) == null) disassemble(ad);
            Function f = fm.getFunctionAt(ad);
            if (f == null) {
                Function cont = fm.getFunctionContaining(ad);
                if (cont != null) {
                    AddressSet rest = new AddressSet(cont.getBody());
                    rest.delete(new AddressSet(ad, cont.getBody().getMaxAddress()));
                    try { cont.setBody(rest); }
                    catch (Exception ex) { println("CyDecompAt: cannot cut " + cont.getName() + ": " + ex); }
                }
                String nm = sp.name != null ? sp.name : String.format("CY_%08x", sp.addr);
                f = createFunction(ad, nm);
                how = "created";
                if (f == null) {
                    w.printf("%n// ==== %s @ %s ====%n// CyDecompAt: <create failed>%n", nm, ad);
                    failed.add(ad + " create");
                    continue;
                }
                CreateFunctionCmd.fixupFunctionBody(currentProgram, f, monitor);
            } else if (sp.name != null && !sp.name.equals(f.getName())) {
                f.setName(sp.name, SourceType.USER_DEFINED);
                how = "renamed";
            }
            pin(f);
            DecompileResults res = d.decompileFunction(f, 180, mon);
            w.printf("%n// ==== %s @ %s ====%n", f.getName(), f.getEntryPoint());
            w.printf("// CyDecompAt: %s, body %s-%s%n", how, f.getBody().getMinAddress(), f.getBody().getMaxAddress());
            if (res != null && res.decompileCompleted()) {
                w.print(res.getDecompiledFunction().getC());
                ok++;
            } else {
                w.printf("// <decompile failed: %s>%n", res != null ? res.getErrorMessage() : "null");
                failed.add(ad + " decompile");
            }
        }
        w.close();
        d.dispose();
        println("CyDecompAt: wrote " + ok + "/" + specs.size() + " functions to " + a[0]
                + (failed.isEmpty() ? "" : "; failed: " + failed));
    }
}
