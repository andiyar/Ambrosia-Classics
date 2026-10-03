// DumpMemory.java — Ghidra headless postScript: writes each initialized memory block of the
// loaded (PEF pidata-unpacked) program as <outdir>/<start-hex>.bin, so Python can resolve
// data addresses (strings, tables, float literals) that the decompiler prints as raw hex.
// Usage: ... -postScript DumpMemory.java <outdir>
// @category Ambrosia
import ghidra.app.script.GhidraScript;
import ghidra.program.model.mem.*;
import java.io.*;

public class DumpMemory extends GhidraScript {
    @Override
    public void run() throws Exception {
        String dir = getScriptArgs()[0];
        new File(dir).mkdirs();
        for (MemoryBlock b : currentProgram.getMemory().getBlocks()) {
            if (!b.isInitialized()) { println("skip " + b.getName()); continue; }
            byte[] buf = new byte[(int) b.getSize()];
            b.getBytes(b.getStart(), buf);
            String fn = dir + "/" + b.getStart().toString() + ".bin";
            FileOutputStream o = new FileOutputStream(fn); o.write(buf); o.close();
            println("block " + b.getName() + " " + b.getStart() + " size " + b.getSize() + " -> " + fn);
        }
    }
}
