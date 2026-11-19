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

        w.printf("%n// ==== functions: entry size span bodyMin bodyMax name [thunk|external] ====%n");
        w.printf("// entry   function entry address%n");
        w.printf("// size    bytes in Ghidra's function body (decimal). Without the decompiler (none on this machine) switch%n");
        w.printf("//         tables (bctr through a jump table) are not followed, so the cases past such a table are left out%n");
        w.printf("//         of the body and size UNDERCOUNTS for those functions%n");
        w.printf("// span    bytes from this entry to the next function entry (decimal); for the last function in a memory%n");
        w.printf("//         block, to that block's end (the code section ends at 100e3a10). Includes alignment padding and%n");
        w.printf("//         any code no function claims (after the last function: the tail of the section), so for a%n");
        w.printf("//         function whose body is contiguous it is an upper bound on its extent%n");
        w.printf("// bodyMin bodyMax  lowest and highest address in the body (the body can have holes)%n");
        java.util.List<Function> fns = new java.util.ArrayList<>();
        FunctionIterator it = currentProgram.getFunctionManager().getFunctions(true);
        while (it.hasNext()) fns.add(it.next());
        int count = 0;
        for (int i = 0; i < fns.size(); i++) {
            Function f = fns.get(i);
            AddressSetView body = f.getBody();
            Address entry = f.getEntryPoint();
            MemoryBlock blk = currentProgram.getMemory().getBlock(entry);
            Address next = (i + 1 < fns.size()) ? fns.get(i + 1).getEntryPoint() : null;
            if (next == null || blk == null || !blk.contains(next)) next = blk == null ? null : blk.getEnd().add(1);
            String span = next == null ? "?" : Long.toString(next.subtract(entry));
            w.printf("%s %6d %6s %s %s %s%s%n", entry, body.getNumAddresses(), span,
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
        if (w.checkError()) throw new IOException("DumpSymbols: write error on " + getScriptArgs()[0]);
        println("DumpSymbols: " + count + " functions, " + ns + " named symbols, " + ne + " externals");
    }
}
