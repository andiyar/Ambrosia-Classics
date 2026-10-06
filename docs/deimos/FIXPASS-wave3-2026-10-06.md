# Deimos Rising RE bank — wave 3+4 fix pass, 2026-10-06

Every review and critic finding for waves 3+4 was checked against the raw disassembly
(`$W/disasm-review3-all.txt`) and applied in place, marked `⚑ corrected (review wave 3, 2026-10-06)`.
The important one: four text-drawing functions had no merge row and two role rows were HIGH on "read"
alone; all four now cite listing lines, and the glyph jump table is at `0x100e542c`. The weightiest
correction is the critic's: the start-up 480 × 416 clip *does* reach the screen — every text builder
keeps it when the format's clip flag is set, so messages, notices, console, frame counter and tallies are
cut at the game-area edge, and so is the level-select colour strip. Settled from the listing: nothing
sets the quit flag during play (#48; the pause screen's quit branch is dead), a scale walk to 100 % ends
at exactly 1.0 (#58), and the text half of #59. 58 stale file-level open items (plus inline mentions)
were struck with pointers. 35 LOW rows in older files now carry the table's label; 19 HIGH rows that said
"listing" with no address now cite one. Labels: table 938 = 698/240/0, unchanged.

**One reversal (for the orchestrator to re-verify).** The handoff said to lower the gameplay-leftovers
§5.1/§5.2 rows to MED; they were kept HIGH and given addresses, because the listing proves them and
lowering would have left unit-def-struct.md's HIGH rows for the same functions in conflict:
`1003dd60..1003ddb8` (4 `lbz/stb` +0..+3, 7 `lwz/stw` +4..+0x1c), `1003ddc0..1003ddf0`, `1003de00..1003de20`,
`1003de30..1003de60` (`lhz/sth 0x4`), `1003de80 addi r0,r3,0x2ac` + loop `1003de88..1003dfa4` stride 0x88,
`1003dfb0..1003e010`, `1003e050 lhz r0,0x8(r4)`…`1003e108 lfs f0,0x54(r4)`, `1003e120..1003e198`,
`1003e1a0..1003e1d0`; `1003f840 lbz r0,-0x60cc(r2)`, `1003f844/1003f84c stw` −0x60dc/−0x60e0,
`1003f874 bl 0x1003fa10`, `1003f890 stw r0,-0x60d4(r2)`; `1003fa28..1003fa44` pop → delete,
`1003fa54 li r4,-0x1; bl 0x100008b0`, `1003fa64 bl 0x1004d3b0`.
