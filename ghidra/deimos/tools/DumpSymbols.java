// DumpSymbols.java — memory blocks, the r2 (TOC) value, every function and every named symbol: args <out>
// Written for the Deimos OS X fragment (ghidra/regen-deimos-osx.sh); generic for any PEF program.
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.listing.*;
import ghidra.program.model.address.*;
import ghidra.program.model.lang.Register;
import ghidra.program.model.lang.RegisterValue;
import ghidra.program.model.mem.MemoryBlock;
import ghidra.program.model.symbol.*;
import java.io.*;
import java.math.BigInteger;

public class DumpSymbols extends GhidraScript {
    @Override
    public void run() throws Exception {
        PrintWriter w = new PrintWriter(new FileWriter(getScriptArgs()[0]));
        w.printf("// program %s  language %s  compiler %s%n", currentProgram.getName(),
            currentProgram.getLanguageID(), currentProgram.getCompilerSpec().getCompilerSpecID());

        w.printf("%n// ==== memory blocks: name start end size perms initialized ====%n");
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            w.printf("%-16s %s %s %8x %s%s%s %s%n", b.getName(), b.getStart(), b.getEnd(), b.getSize(),
                b.isRead() ? "r" : "-", b.isWrite() ? "w" : "-", b.isExecute() ? "x" : "-",
                b.isInitialized() ? "init" : "uninit");
        }

        w.printf("%n// ==== r2 (TOC) as recorded in the program context ====%n");
        Register r2 = currentProgram.getRegister("r2");
        ProgramContext ctx = currentProgram.getProgramContext();
        BigInteger def = null;
        if (r2 != null) {
            RegisterValue dv = ctx.getDefaultValue(r2, currentProgram.getMinAddress());
            if (dv != null && dv.hasValue()) def = dv.getUnsignedValue();
            w.printf("default r2 = %s%n", def == null ? "(none)" : def.toString(16));
            // one line per distinct value: how many context ranges carry it, first and last range start
            java.util.TreeMap<String, String[]> seen = new java.util.TreeMap<>();
            java.util.TreeMap<String, Integer> cnt = new java.util.TreeMap<>();
            AddressRangeIterator ri = ctx.getRegisterValueAddressRanges(r2);
            while (ri.hasNext()) {
                AddressRange r = ri.next();
                BigInteger v = ctx.getValue(r2, r.getMinAddress(), false);
                String k = v == null ? "(none)" : v.toString(16);
                String a = r.getMinAddress().toString();
                if (!seen.containsKey(k)) seen.put(k, new String[] { a, a });
                seen.get(k)[1] = a;
                cnt.merge(k, 1, Integer::sum);
            }
            for (String k : seen.keySet()) {
                w.printf("r2 = %s at %d context ranges, first %s, last %s%n", k, cnt.get(k), seen.get(k)[0], seen.get(k)[1]);
            }
        }
        for (Symbol s : currentProgram.getSymbolTable().getSymbols("TOC")) {
            w.printf("symbol TOC at %s%n", s.getAddress());
        }

        w.printf("%n// ==== functions: entry size(bytes) bodyMin bodyMax name [thunk|external] ====%n");
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        int count = 0;
        while (it.hasNext()) {
            Function f = it.next();
            AddressSetView body = f.getBody();
            w.printf("%s %6d %s %s %s%s%n", f.getEntryPoint(), body.getNumAddresses(),
                body.getMinAddress(), body.getMaxAddress(), f.getName(),
                f.isThunk() ? " [thunk]" : (f.isExternal() ? " [external]" : ""));
            count++;
        }
        w.printf("// %d functions%n", count);

        w.printf("%n// ==== named symbols (non-default, non-external): address type source name ====%n");
        SymbolIterator si = currentProgram.getSymbolTable().getAllSymbols(true);
        int ns = 0;
        while (si.hasNext()) {
            Symbol s = si.next();
            if (s.getSource() == SourceType.DEFAULT || s.isExternal()) continue;
            w.printf("%s %s %s %s%n", s.getAddress(), s.getSymbolType(), s.getSource(), s.getName(true));
            ns++;
        }
        w.printf("// %d named symbols%n", ns);

        w.printf("%n// ==== external symbols (imports): library::name ====%n");
        SymbolIterator ei = currentProgram.getSymbolTable().getExternalSymbols();
        int ne = 0;
        while (ei.hasNext()) {
            Symbol s = ei.next();
            w.printf("%s%n", s.getName(true));
            ne++;
        }
        w.printf("// %d external symbols%n", ne);
        w.close();
        println("DumpSymbols: " + count + " functions, " + ns + " named symbols, " + ne + " externals");
    }
}
