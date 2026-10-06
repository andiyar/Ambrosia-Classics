# Cythera 1.0.4 — the dialogue / keyword system

Register: **code reading**. Every claim carries HIGH (quoted bytecode or decompiled/disassembled
lines prove it), MED (inferred) or LOW (conjecture). Listings are `ghidra/cythera-scripts/<seg>.txt`
(`docs/cythera/tools/scriptdis.py`); native code is `ghidra/Cythera_pef.decompiled.c` plus
`ppcdis.py` listings of functions Ghidra did not decompile (method below). Dialogue text is Ambrosia's: it is
quoted only as a few bytes of evidence, never transcribed.

## 0. Scope, method, what was not read

- **Scope**: how a conversation starts, prints, reads the player, matches keywords, offers the
  keyword "chips", prompts (yes/no, free text, numbers, menus), ends; the per-character knowledge
  gates; barks; the conversation UI modes; a catalogue of the 127 talk methods.
- **Builds on** (cited, not repeated): script-vm.md §4/§8 (statements 0x8A/0x8E/0x8F/0x90, text
  terminator rule), script-builtins.md (A4, B4, BB, C0, E8/E9, F4), rules.md §5 (TalkCommand,
  CanTalk, STR# 128), data-format.md §6.2 (GetCharacterName, DrawPortrait), census §2/§5/§7,
  trade-economy.md (shop/money routines R0EA5/R0EA9/R0D04/R0D05 — not re-read here).
- **Native method** ⚑ corrected (wave 1 2026-10-03), banked tools only: decompiles via `python3
  ghidra/find_func.py --func '<name>' --file ghidra/Cythera_pef.decompiled.c`; entry/extent/name via
  `python3 docs/cythera/tools/tb.py --at <hex>` / `--grep '<re>'`; bodies Ghidra lacks (`tb.py
  --missing ghidra/Cythera_pef.decompiled.c`: `ForceOut`, `mygets`, `mygetch`, `myprintstr`, the
  TConvResponseMode/TConvMoreMode/TPickMode Key/MouseRoutines) via `python3 docs/cythera/tools/ppcdis.py
  --func '<name>'` or `<start> <end>`; every listing quote is ppcdis output with its command beside it.
  Vtable calls (bare `FUN_100c50e8()`, script-vm §6): slot from the listing (`lwz r12,<slot>(r12)`),
  vtable from the ctor's store, target = data word w → TVector 0x100CD280+w → code 0x10000000+word0:
  `python3 -c "import sys;sys.path.insert(0,'docs/cythera/tools');import toc;vt,s=0x100d5298,0x114;w=toc.data_u32(vt+s)[0];print(hex(0x10000000+toc.data_u32(toc.DB+w)[0]))"`
  (→ 0x1003f314 = `mygets`), then `tb.py --at`.
- **Corpus method** ⚑ corrected (wave 1 2026-10-03): for each listing whose dictionary has
  `sel12/talk`, the region = the talk method's lines plus every local subroutine it reaches through
  `sub_XXXX` (transitively), dead-code (`x`) lines skipped; statements are counted by the mnemonic
  column; **routine calls** (R08xx, R0Exx, R0Dxx) are **not** folded in. Prints `127, 108, 1325,
  1551, 88`; the §14 in/br/w/pr/sp columns and builtin totals come from the same region set:
```sh
python3 - <<'PY'
import glob,re,collections as C; T=C.Counter()
for f in sorted(glob.glob('ghidra/cythera-scripts/*.txt')):
  R={}; k=None; todo,seen=['sel12/talk'],set()
  for l in open(f):
    m=re.match(r'; (?:==== method (\S+) @|---- local subroutine @)(\w{4})',l)
    if m: k=m[1] or 'sub_'+m[2]; R[k]=[]
    elif k and re.match(r'\w{4}:[ >]',l): R[k].append(l)
  while todo:
    k=todo.pop()
    if k in R and k not in seen: seen.add(k); todo+=re.findall(r'sub_\w{4}',''.join(R[k]))
  for l in (l for k in seen for l in R[k]): op=l[51:61].strip(); T[op]+=1; T['words']+=op=='match' and len(l[61:].split(' else')[0].split(','))
  T['methods']+=bool(seen)
print({k:T[k] for k in ('methods','input','match','words','prompt')})
PY
```
- **Not read**: TConvResponseMode Draw/Idle, TPickMode Key/Draw, THowManyMode input, TModalMode,
  TSimpleInteraction, TJournal (`IsJournalable`/`WriteJournal` only named), TTextContext `&`/`<d`
  codes; per-character meanings of flag bits 0–5. No hintbook PDF is in the installed folder (only
  a "Stuck? Get the Cythera Hintbook" link file), so no LOW hintbook claims are made.

## 1. How a conversation starts

**1.1 Player-initiated.** `TalkCommand__8TGameSysFs @ 100524b0` [HIGH]:
```
if ((puVar2[sVar4 * 0x20 + 0x16] == -0x6f) || ((*(ushort *)(puVar2 + sVar4 * 0x20 + 6) & 0x4000) != 0)) { … They_are_asleep … return; }
_BeginTalking__13TStatusWindowFv(*(undefined4 *)puVar1);
_ShowPortrait__13TStatusWindowFss(*(undefined4 *)puVar1,(int)*(short *)PTR_DAT_100cdbec,2);
if ((sVar4 < 0x100) && ((*(ushort *)(puVar2 + sVar4 * 0x20 + 6) & 1) != 0)) {
  _ShowPortrait__13TStatusWindowFss(*(undefined4 *)puVar1,param_2,0); … _DoInterp__7TInterpFs5VAddr(auStack_34,0xc,local_38); }
else { _DoInterp__7TInterpFs5VAddr(auStack_3c,0xc,param_2 & 0xffff | 0x40000000); }
```
- Party leader's portrait goes to **slot 2**, the partner's to **slot 0**; selector **12** goes to
  the class-0x40 character object only when the target is a character (< 0x100) **and alive**
  (CharEntry +6 bit 0). [HIGH]
- A **dead** character (or any prop ≥ 0x100) gets selector 12 as a **class-0 object**, i.e. it is
  dispatched to the **prop-type** class `0x1000 + type` (script-vm §2.1) with no partner portrait.
  The six prop-type talkers are 102E/10E5 "guard", 104E/111B "corpse", 1114 "metal door", 1121
  "ghost" (catalogue). [HIGH for the branch; MED that this is how corpses "talk"]
- No dictionary entry → `DoInterp0` falls back to routine `0x3000 + 12` = **0x300C**, which prints
  one fixed line and returns (`300C @0003 text "You are met with stony silence.\n"`, `@0023 return 0`). [HIGH]
- After the method returns: `EndTalking`, the partner monster's status bit 3 (IsAngry) is cleared
  (`& 0xfff7`), `HeartBeat(1)`. [HIGH]
- `CanTalk__8TGameSysFs @ 10050348`: id 0 → no; < 0x100 → yes; a prop with an active monster →
  yes; else only if the prop answers property 0x1E with 2 (`HasProperty(&l,0x1e,…)`,
  `… >> 4 == 2`). [HIGH] Whether the Talk command consults CanTalk was not traced.

**1.2 The conversation object.** `BeginTalking__13TStatusWindowFv @ 10035dc0` allocates a
`TConversation` (0xA54 bytes) and stores it at status-window +0x34; `EndTalking @ 10035e50`
deletes it (vtable delete) and zeroes +0x34. A **new conversation per talk** — the keyword chip
list (§5) is rebuilt every time. [HIGH] The constructor (`__ct__13TConversationFv @ 1003b02c`)
publishes itself in the global the VM reads (`*_DAT_100cdcc8 = param_1`), clears 100 answer slots
(`param_1[sVar2 + 0x22e] = 0`, i.e. +0x8B8) and seeds them from `STR# 128`:
`.glue::GetIndString(&local_118,0x80,iVar1); … _AddAnswer__13TConversationFPcs(param_1,auStack_117,local_118);`
[HIGH]. `STR# 128` (Cythera Data.rsrc, read with `tools/rsrc.py` this session) = `Bye`, `Name`,
`Job`, `Where Is...` [HIGH].

**1.3 NPC-initiated speech.** Scripts open the same window themselves with builtins E8/E9:
`begin_talking` 22 calls / `end_talking` 24 calls, of which 12/12 in character **signal**
(selector 21) methods, the rest in use/use_on/enter/first_visit methods. Shape (1801): `03C1: e8 40 begin_talking()`,
`03C3: a4 42 00 01 41 02 40 show_portrait(1, 2)`, `03CA: a4 42 00 7e 41 00 40 show_portrait(126, 0)`,
`09CC: e9 40 end_talking()`
[HIGH for the bytes and counts; MED that every site follows this order]. Signal-driven speech
has no `input` (0 of 108 `input` statements lie outside talk methods — §3). [HIGH]

## 2. How text is printed

**2.1 Path.** Statement 0x01–0x7F (literal text) and 0x8A (print) both end in
`_HandleMapping__FPcRl(pcVar9,_DAT_100cecfc); _OutStr__FPc(pcVar9);` (DoInterpAt). `OutStr @
10091738` → `TStatusWindow::myprintf("%s", s)` → `myprintstr__13TStatusWindowFPcs`, which, when a
conversation exists (`*(int *)(param_1 + 0x34) != 0`), forwards to the conversation's
`myprintstr` (vtable glue `FUN_100c50e8(*(param_1+0x34),param_2,param_3)`); without one, `*`
calls `TTextOut::More` and CR/LF break lines in the status pane. [HIGH]

**2.2 `^` capitalises the next letter.** `HandleMapping @ 10080bb8`: `if (*param_1 == '^')
*param_2 |= 1;` and the next letter is upper-cased (`*pcVar1 = *param_1 + -0x20`); the state word
`_DAT_100cecfc` survives across statements, so `text "…meet you ^"` + `print last_input` prints the
(lower-cased, §3.3) input with a capital (1813 @00AB/@00C1). [HIGH]

**2.3 Quotes split the window into two panes.** `myprintstr__13TConversationFPcs @ 1003d054`
(undecompiled) keeps an "inside quotes" byte at +0x4C — ⚑ corrected (wave 1 2026-10-03), quoted from
`ppcdis.py --func 'myprintstr__13TConversation'` (r27 = TOC 0x100ce7f4 = `"`, `toc.py 100ce7f4`):
`1003d114: 2c000022  cmpwi r0,34` · in quotes: `1003d134: 48000109  bl 0x1003d23c  ;
.AppendConv__13TConversationFPcs`, `1003d140: 389b0000  addi r4,r27,0`, `1003d144: 38a00001  li r5,1`,
`1003d148: 480000f5  bl 0x1003d23c`, `1003d15c: 38000000  li r0,0`, `1003d160: 981f004c  stb
r0,76(r31)` · outside: `1003d178: 480001cd  bl 0x1003d344  ; .AppendMessage__13TConversationFPcs`,
`1003d18c: 38000001  li r0,1`, `1003d190: 981f004c  stb r0,76(r31)`, `1003d194: 7fbeeb78  mr r30,r29`.
Text outside quotes goes to the **message pane** (`AppendMessage`/`ShowMessage`, narration; then
+0x4C := 1 and the next run starts **at** the opening quote, `mr r30,r29`); text from the opening
`"` up to the closing one, plus the TOC `"` (1 byte), goes to the **talk pane**
(`AppendConv`/`ShowTalking`, then +0x4C := 0; drawn beside the current speaker's portrait,
`OffsetRect(… *(short *)(param_1 + 0xa4e) * 0x58)`). Each pane holds ≤ 0x3FF bytes
(`AppendConv`: `if (0x3ff < param_3 + len) param_3 = 0x3ff - len`). [HIGH]

**2.4 `*` = "more" pause.** ⚑ corrected (wave 1 2026-10-03), same listing: at `*` (`1003d0a0:
2c00002a  cmpwi r0,42`) the run is flushed with length `p − 1 − start` (`1003d0b4: 381dffff  addi
r0,r29,-1`, `1003d0c0: 7cbe0050  subf r5,r30,r0`), the next run starts at `p + 1` (`1003d100:
3bdd0001  addi r30,r29,1`), and `ConvMore @ 1003ceb0` runs (`ppcdis.py --func 'ConvMore__13TConv'`):
return if +0x4F (`1003ced0: 8803004f  lbz r0,79(r3)`); unless +0x38 "skip" (`1003cf08: 881f0038
lbz r0,56(r31)`) run a `TConvMoreMode` (`1003cf38: 3802fe8c  addi r0,r2,-372  ; = 0x100d510c`);
then +0x4F := 1 (`1003cf78: 981f004f  stb r0,79(r31)`). [HIGH]
- Any key ends the pause; **Esc** also sets interaction +0x38 = 1 (`ppcdis.py --func
  'KeyRoutine__13TConvMoreMode'`: `1003ce50: 2c00001b  cmpwi r0,27`, `1003ce60: 98030038  stb
  r0,56(r3)`) until the next prompt (`GetResponse`: `*(undefined1 *)(param_1 + 0x38) = 0;`). [HIGH]
- A click calls TConversation vtable +0xF4, then +0xF8 (`ppcdis.py --func 'MouseRoutine__13TConvMore'`:
  `1003cd0c: 818c00f4  lwz r12,244(r12)`, `1003cd50: 818c00f8  lwz r12,248(r12)`) = `IsJournalable
  @ 1003c4e4` / `WriteJournal @ 1003c628` (§0 one-liner): journalable → `AutoEye("[Write To
  Journal]")` + WriteJournal, the pause stays; else `*MORE*` and `Done`. [HIGH calls; MED for what
  is recorded; TJournal not read]
- ⚑ quirk: the byte **just before** `*` is dropped from the flushed run. Harmless after a closing
  quote (that run is already empty); after narration such as `…to the north.*` the full stop is
  lost. [HIGH for the length arithmetic quoted above; not observed on screen]

**2.5 Markup inside a pane.** `__ct__12TTextContextFPCcssss @ 10075d98` (markup on unless
`param_6 & 1`): `\n`/`\r` new line; **`@` starts a hint run** (`*(undefined1 *)(puVar4 + 3) = 1`)
that ends at the first non-letter; `<d` / `>` switch text style; `&` has its own handling (not
read). Both
`ShowTalking` and `ShowMessage` pass the run list to `ScanForHints`, which `AddAnswer`s every hint
run (`if ((*(char *)(param_2 + 6) != '\0') && (*(short *)(param_2 + 0xc) != 0)) _AddAnswer…`).
So `@word` in either pane becomes a keyword chip (§5). [HIGH for '@' and ScanForHints; MED for the
exact word extent; LOW for the meaning of the `<d` styles]

**2.6 Statement 0x8A print** formats integers `%d`, True/False/Nil as `true`/`false`/`None`, objects
via `PrintObj`, tag-2 global strings via `GetGlobStr`, strings directly, other blocks `<%x>`
(TOC 0x100cecf0/ec/e8/e4/e0 resolved with `toc.py`: `%d`, `true`, `false`, `None`, `<%x>`). [HIGH]
In talk methods the printed values are locals (22), `globstr(1:time_of_day)` (19, e.g. 1810
@0076), `globstr(2:player_name)` (13), `globstr(10:last_input)` (8), party-size prices (10).
`GetGlobStr__Fs`: case 10 returns `_DAT_100cdf60`, the input buffer of §3. [HIGH]

## 3. Reading the player: statement 0x8E `input`

**3.1 Native.** ⚑ corrected (wave 1 2026-10-03): DoInterpAt case 0x8E, `ppcdis.py 10081a00
10081a50` (DoInterpAt's prologue loads r24 = TOC 0x100cdf60, the input buffer `_DAT_100cdf60`, and
r19 = TOC 0x100cdcc8, the conversation pointer: `ppcdis.py 10080ca0 10080cac`):
`10081a04: 818c0104  lwz r12,260(r12)`, `10081a08: 480436e1  bl 0x100c50e8`, `10081a14: 38980000
addi r4,r24,0`, `10081a18: 38a00040  li r5,64`, `10081a20: 38c00001  li r6,1`, `10081a24: 818c0114
lwz r12,276(r12)`, `10081a30: 88180000  lbz r0,0(r24)`, `10081a40: 80829a5c  lwz r4,-26020(r2)  ;
TOC 0x100cecdc`, `10081a44: 480352c5  bl 0x100b6d08`.
TConversation vtable at 0x100d5298 (`*param_1 = &PTR_PTR_100d5298` in the ctor): +0x104 →
0x1003dfd4 `ForceOut__13TConversationFv`, +0x114 → 0x1003f314 `mygets__13TConversationFPcsUc`,
+0x118 → 0x1003f4dc `mygetch__13TConversationFPc`, +0x11C → 0x1003f650 `mygetnum` (§0
one-liner + `tb.py --at`). TOC 0x100cecdc = `bye`; `FUN_100b6d08` is strcpy (decompile). So
**`input` = `ForceOut(); mygets(buf, 64, withAnswers=1); if (buf[0]==0) strcpy(buf,"bye")`** — an
empty line ends the conversation by the script's own `bye` branch. It returns nothing on the
stack; scripts read the result only through 0x90 and `globstr(10)`. [HIGH]
`ForceOut` (`ppcdis.py --func 'ForceOut__13TConversation'`) = unless +0x4F (`1003dfe8: 8803004f
lbz r0,79(r3)`), `ShowTalking` if +0x4D is clear (`1003dff4: 881f004d  lbz r0,77(r31)`) and
`ShowMessage` if +0x4E is clear (`1003e008: 881f004e  lbz r0,78(r31)`); then +0x4C := 0
(`1003e020: 981f004c  stb r0,76(r31)`). [HIGH]

**3.2 `mygets` (1003f314).** ⚑ corrected (wave 1 2026-10-03), `ppcdis.py --func 'mygets__13TConv'`:
calls `ForceOut` first (`1003f338: 818c0104  lwz r12,260(r12)`); with `withAnswers` walks the 100
slots at +0x8B8 (`1003f364: 380308b8  addi r0,r3,2232`, `1003f428: 2c000064  cmpwi r0,100`), skips
null and −1, upper-cases each first letter **in place** (`1003f3d4: 2c000061  cmpwi r0,97`,
`1003f3ec: 38a3ffe0  addi r5,r3,-32`), collects ≤ 20 (`1003f414: 2c000014  cmpwi r0,20`) into a
local array filled backwards (`1003f3a8: 20600014  subfic r3,r0,20`), calls `GetResponse(this,
buf, NULL, len, list, n)`, then `RemoveAnswer(buf)` if `buf[0] != 0` (`1003f470: 480017f9  bl
0x10040c68  ; .RemoveAnswer__13TConversationFPc`); without: `GetResponse(this, buf, NULL, len,
NULL, 0)`. [HIGH] Effects: chips show in reverse slot order (newest-slot first) [MED]; **the topic just asked is removed from the chips** (matching on
its first four letters, §5) [HIGH].

**3.3 `GetResponse__12TInteractionFPcPcsPPcs @ 1003ec2c`.** Lays out ≤ 20 chips (each drawn as
`"- "` + text) and, when a buffer is given, a text field (0x80 px beside chips, 0x100 px alone;
`TENew`), then runs a
`TConvResponseMode` modal loop, then **lower-cases A–Z in the buffer**:
`if (('@' < cVar6) && (cVar6 < '[')) cVar6 = cVar6 + ' ';`. [HIGH]
`TConvResponseMode` (vtable 0x100d50d4 — ctor `*param_1 = &PTR_PTR_100d50d4;`; slot +0x10 →
0x1003e378 MouseRoutine, +0x1C → 0x1003e8ec KeyRoutine (+0xC → 0x1003e17c DrawRoutine, +0x18 →
0x1003e778 CursorRoutine, both unread) by the §0 one-liner + `tb.py --at` ⚑ corrected (wave 1
2026-10-03); `tb.py --grep TConvResponseMode`):
- `KeyRoutine @ 1003e8ec` ⚑ corrected (wave 1 2026-10-03), `ppcdis.py --func 'KeyRoutine__17TConv'`:
  key mapped through the to-lower table (`1003e924: 38623806  addi r3,r2,14342  ; = 0x100d8a86`,
  §6). Return (13) / Enter (3) with a text field → `TEGetText`, `BlockMove` of the full buffer
  length (`1003e970: a8bf002c  lha r5,44(r31)`; 64 for `input`), NUL at the TE length only when
  shorter (`1003e98c: 7c030000  cmpw r3,r0`, `1003e990: 4080001c  bge 0x1003e9ac`), `Done`. Other
  keys: with a choice string (mode +0x24) a key not in it (`FUN_100b6e38`, strchr) beeps unless it
  is Backspace with a text field; then `TEKey` (text field) or store the key's index and `Done`.
  `mygets` passes no choice string, so typed lines are unfiltered. [HIGH] ⚑ An entry of ≥ 64
  characters is left without a NUL by this routine. [HIGH code; not observed on screen]
- `MouseRoutine @ 1003e378`: a click in chip *i* stores *i* and, when a buffer length is set,
  **copies the chip text into the buffer** (`ppcdis.py --func 'MouseRoutine__17TConv'`: `1003e5e8:
  a81f002c  lha r0,44(r31)`, `1003e604: 7c84002e  lwzx r4,r4,r0`, `1003e608: 48078701  bl
  0x100b6d08`), `Done` — a chip behaves as if typed (`Where Is...` → `where is...`). [HIGH]

**3.4 Loop shape.** All 108 `input` statements sit inside talk-method regions (corpus count; the
census total is 108). The compiled shape is one `input` at a fixed label, a chain of `match`
statements whose bodies end with `goto <input label>`, and `bye` (or the end) returning. 1810:
`0088:>8e input`, `0089: 90 6e 61 6d 65 00 00 d4 match name else -> 00D4`, `00CA: 9f 0f 00 30 41 07
40 call R0F00(A30, 7)`, `00D4:>90 62 79 65 00 00 f4 match bye else -> 00F4`, `00ED: 8b 41 00 40
return 0`, `04B8:>90 2a 00 05 04 match * else -> 0504`.
[HIGH for 1810; MED as the general shape — 3 talk methods have 2 `input` labels (183C, 183E,
1864), 22 have none]

## 4. Keyword matching: statement 0x90 `match` (INDEX item 13)

**4.1 Native.** DoInterpAt (decompiled):
```
while (((local_50[0] = … + 1, local_88 != 0 && (local_88 != 0x2c)) && (local_88 < 0x80))) { *pbVar13 = local_88; … }
*pbVar13 = 0;
if (local_ac[0] == 0x2a) { bVar1 = true; }
else { iVar19 = FUN_100b6dc8(local_ac,pcVar6,(int)pbVar13 - (int)local_ac); if (iVar19 == 0) bVar1 = true; }
} while (local_88 == 0x2c);
```
and `FUN_100b6dc8`, ⚑ corrected (wave 1 2026-10-03): it **is** in the main dump (`// ==== FUN_100b6dc8
@ 100b6dc8 ====`; `python3 ghidra/find_func.py --func FUN_100b6dc8 --file ghidra/Cythera_pef.decompiled.c`; line breaks joined): `param_3 = param_3 + 1; while( true ) { param_3 = param_3 + -1;
if (param_3 == 0) { return 0; } pbVar2 = pbVar2 + 1; uVar1 = (uint)*pbVar2; pbVar3 = pbVar3 + 1;
if (uVar1 != *pbVar3) break; if (uVar1 == 0) { return 0; } } return uVar1 - *pbVar3;`
(the listing agrees: `ppcdis.py 100b6dc8 100b6e08`, `100b6dd8: 8c030001  lbzu r0,1(r3)` …
`100b6de8: 7c650050  subf r3,r5,r0`). `FUN_100b6dc8` is plain **`strncmp(word, input,
strlen(word))`**: case-sensitive, no folding. [HIGH]

**4.2 Semantics.** [HIGH unless marked]
- A keyword matches when it is a **prefix of the whole input line** (`name` matches "name",
  "names", "name please"; it does not match "your name"). Only the first word position counts.
- **Minimum length = the keyword's own length**: typing fewer letters than the keyword fails
  ("nam" ≠ `name`). No other minimum.
- **Case**: the input is lower-cased by `GetResponse` (§3.3); a keyword containing upper case could
  never match a typed line. Corpus: 0 keywords contain A–Z (corpus scan). The key for single-key
  prompts is lower-cased too (§6).
- **Several words per branch**, comma-separated, OR-ed: the loop keeps reading after a hit. 179 of
  1 325 talk-region `match` statements carry 2+ words (1 551 words in all).
- `*` (only when it is the **first byte** of a word) matches anything — 109 talk methods end their
  chain with it.
- **First match wins**: branches are tested in listing order; there is no scoring.
- Word bytes stop at `,`, NUL or ≥ 0x80; **spaces are kept**. ⚑ Seven keyword lists have a space
  after the comma, so the second alias starts with a blank and only matches input that itself
  starts with a space — unreachable by chip, reachable only by typing a leading blank:
  `1818 @009E 90 6e 61 6d 65 2c 20 65 75 72 79 00 … match name, eury`; also 1828 @03A0,
  1829 @05F3, 182A @0596, 186D @155F, 1878 @0975, 080F @00C6. [HIGH bytes + loop]
- Word lengths over the talk corpus: 1 char 252 (`*` 109, `y` 71, `n` 71, `0` 1), 3 chars 273,
  4 chars 1 017, 5+ chars 9 (`very easy`, `very hard`, `thread`, the six blank-prefixed aliases).
  The convention is "first four letters" — the same width the chip list de-duplicates on (§5).
  [HIGH counts; MED that 4 is a deliberate convention]
- Commonest: `*` 109, `bye` 108, `job` 107, `name` 100, `y`/`n` 71 each; numeric words exist
  (`201` 1802 @23F0, `742` 1810 @0391).

**4.3 Outside talk methods.** 1 556 − 1 325 = 231 `match` statements live elsewhere: the page-0x08
topic libraries (§8) and a few prop `use` methods (1036 fountain, 1110 button, 1114 metal door,
1121 ghost) that read a `prompt "*"` line. They read the same input buffer. [HIGH]

## 5. The keyword chips (TConversation answer list)

- Storage: 100 `char*` slots at TConversation +0x8B8, malloc'd copies. [HIGH]
- `AddAnswer(s, n) @ 10040a54`: if `FindAnswer` finds no equal entry, store a copy in the first
  free slot (allocation failure → `ExitToShell`). [HIGH]
- `FindAnswer @ 10040e64` → `EqualNStr(new, slot, 4) @ 10040d34`: compares
  `n = 4` characters, or `strlen+1` (whole string) when the new string is shorter than 4, folding
  A–Z to a–z (`if (('@' < cVar1) && (cVar1 < '[')) cVar1 = cVar1 + ' ';`). Two topics are "the
  same chip" when their first four letters agree, case-insensitively. [HIGH]
- `RemoveAnswer(s) @ 10040c68`: `FindAnswer(s, strlen)` then free + null the slot — called by
  `mygets` with whatever the player typed or clicked. [HIGH]
- Sources: `STR# 128` defaults (§1.2); every `@word` hint shown in either pane (§2.5); builtin
  **F4 `add_answer(string)`** (18 calls: 17 in talk methods, e.g. 1802 @0C46 `add_answer("Help")`,
  1822 @0275/027E/0290 `Leave`/`Wait`/`Follow` guarded by `R0F13(34)` inparty; 1 in 0816, which
  re-adds `Where Is` before showing its menu). [HIGH]
- Display: at most 20, first letter capitalised in place (§3.2). [HIGH]
- Net effect in code ⚑ corrected (wave 1 2026-10-03): a topic enters the chip row when the NPC
  prints `@word` and leaves it once the player asks it. [MED — synthesis of the above]

## 6. Prompts: statement 0x8F (INDEX item 13 — identity settled)

DoInterpAt case 0x8F, ⚑ corrected (wave 1 2026-10-03) `ppcdis.py 10081a50 10081b08`: `GetString`
the operand (`10081a5c: 48001555  bl 0x10082fb0  ; .GetString__7TInterpFPUcPUc`), then
- first byte `*` (`10081a70: 2c04002a  cmpwi r4,42`) → `ForceOut; mygets(buf, 64, 0)`
  (`10081a94: 38a00040  li r5,64`, `10081a9c: 38c00000  li r6,0`) — a free-text line with **no
  chips** and **no `bye` default** (an empty line stays empty; only a `*` match catches it). [HIGH]
- otherwise → `ForceOut; c = mygetch(string)` (`10081ad0: 818c0118  lwz r12,280(r12)`);
  `if (c == 0) c = buf[0]; buf[0] = c; buf[1] = 0` (`10081b00: 98d80000  stb r6,0(r24)`,
  `10081b04: 98980001  stb r4,1(r24)`). [HIGH]

`mygetch__13TConversationFPc @ 1003f4dc` (`ppcdis.py --func 'mygetch__13TConv'`): `ForceOut`;
length > 20 → `SysBeep` (`1003f524: 480831dd  bl 0x100c2700`, `SysBeep` in the dump) and clamp to
20; if the string equals TOC 0x100ce7e4 `yn` (`1003f538: 4807785d  bl 0x100b6d94`, strcmp) the
chips are TOC `Yes`/`No` (0x100ce7e0/dc), else one upper-cased 2-byte string per character at
sp+56+2i; `GetResponse(this, NULL, choices, 0, list, n)`; `return choices[index]` (`1003f608:
7c7c00ae  lbzx r3,r28,r0`). [HIGH] ⚑ In the per-character branch every list slot gets the same
pointer sp+64 (`1003f56c: 38830008  addi r4,r3,8`, `1003f578: 7c83012e  stwx r4,r3,r0`), the
string of character 4. [HIGH code; unreached — every shipped prompt is `"yn"`/`"*"`, B5 never called]
In `TConvResponseMode::KeyRoutine` the key is first mapped through the 256-byte table at
`r2+14342` = 0x100D8A86 (bytes 0x41–0x5A and 0x61–0x7A both read `abc…z` in `toc.D`: **to-lower**) and compared with the choice string, so keys are
case-insensitive for lower-case choice strings. [HIGH]

Corpus: 95 prompts = **77 `"yn"`** + **18 `"*"`** (all 88 in talk methods are among them). The
`yn` form is always followed by `match y` / `match n`, e.g. 1804 `08B9: 8f 79 6e 00 prompt "yn"`,
`08BD: 90 79 00 09 24 match y else -> 0924`, `0924:>90 6e 00 09 64 match n else -> 0964`.
The `*` form is used for names/passwords and echoed with `^` + `globstr(10)` (1813 @00A8–00C1).
[HIGH] Builtin B5 `ask_digit` (mygetch on `0123456789`, TOC 0x100ce7d8) is never called. [HIGH]

## 7. Numbers, party choice, menus

**7.1 B4 `how_many(prompt or Nil, a, b)`** → `HowMany__12TInteractionFPcss @ 10041c54`: without a
conversation it builds a standalone `TSimpleInteraction`; with one, the prompt is `myprintf`'d
into it; then `THowManyMode` (`__ct @ 100412c0`):
`*(short *)param_1[5] = (short)param_5; … NewControl(…, value = *param_1[5], min = param_4, max = param_5, 0x3e91, …)`
— **a = minimum, b = maximum, and the slider starts at b**; the chosen value is returned.
[HIGH; closes the "B4's two integer arguments" open item of script-builtins §4]
Live calls: 1811 @026C and 185D @0097 `how_many("Give how many oboloi?", 0, L00)`; the other two
(0E92 @0039, 0EA4 @0054, `how_many(Nil, 0, 200)`) are in routines no code calls (census §7). [HIGH]

**7.2 BB `who_will_prompt(string)`** → `WhoWill__12TInteractionFPcUc(string, 0) @ 10041114`: the
four calls (0E91/0E92/0E94/0EA4 @0003) are all in **never-called** routines (census §7), so no
shipped 1.0.4 dialogue asks "who will…". Candidates = alive party members; 0 → 0, exactly 1 →
that member **without asking**; else `WhoWill__12TInteractionFPs @ 1003f720` shows the names
(`GetCharacterName(…,1)`) plus a last chip `None` (TOC 0x100ce7d4) and maps `None` to 0. The
string is passed only to the standalone `TSimpleInteraction` (no-conversation case). [HIGH]

**7.3 C0 `pick_item(prompt, format, items, buttons)`** → `TInteraction::PickItem` / `TPickMode`
(vtable 0x100d509c). `MouseRoutine__9TPickModeF5Points @ 10040200` stores **−(k+1)** for button
*k* (⚑ corrected (wave 1 2026-10-03) `ppcdis.py --func 'MouseRoutine__9TPickMode'`:
`10040824: 381a0001  addi r0,r26,1`, `1004082c: 7c0000d0  neg r0,r0`, `10040834: b0030000  sth
r0,0(r3)`), an item index ≥ 0 otherwise; items are capped at 20 (`sVar8 < 0x14` in Builtin_C0). Scripts test it accordingly: 0816 @013B `jf (L09 == -1)`,
1821 @0F8E `jf (L05 >= 0)`. The **0x45 inline blocks** carry these tables — the button list
(`blk@0F7F … .array[1] [0] @0F85 "Cancel"`, 1821/1804) and, for "Where Is", a 13-entry array of
`[room, label, phrase, x, y, tail]` rows (0809 @0131 `call R0816(A30, blk@0138, 1)`). [HIGH for the
return code and blocks; MED for the per-field meaning of the Where-Is rows]
Use: 8 calls in talk methods, 4 in page-0x0E routines (shop/training — trade-economy.md), 1 in
0816, 1 in a signal method. [HIGH counts; MED for the purposes]

**7.4 Where Is.** The `Where Is...` chip (STR# 128) → `wher` in a regional library (0809 @0129,
080A, 080B) → R0816: `add_answer("Where Is")` (it was just removed, §3.2), filter the rows to the
current room, `pick_item("Directions to Where?", "%p%s", L01, L00)`, print the chosen phrase. [HIGH
bytes; MED reading]

## 8. The standard skeleton and the shared topic libraries

Representative: **1810 (Atreus)**, 10 keyword branches. [HIGH, listing lines quoted]
1. Narration (`0005 text "You see a sly…"`) — outside quotes → message pane.
2. Greeting chosen by the **name-known bit**: `0048 jf R0F02(A30, 7) -> 0070` → "well met again"
   vs "Good " + `print globstr(1:time_of_day)` (0076).
3. `0088 input`, then `match name` → speech + `00CA call R0F00(A30, 7)` (setbit 7) → back to input.
4. `match bye` → farewell, `00ED return 0`.
5. `match job` with an **activity gate** (`jf (A30.f15:activity == 146)` — at work or not), topic
   words marked `@buying`/`@selling` so they appear as chips.
6. Topic branches (`buy,buyi` → trade routine R0EA5, `sell` → R0EA9 — trade-economy.md;
   neighbours' names; a numeric word).
7. `04B8 match *` → `jf !R080D(A30) -> 0501`, `jf !R0801(A30) -> 0501`, else a "not sure what you
   are getting at" line; every path `goto 0088`.

Corpus shape: **97** talk methods have all of `name`, `job`, `bye`, `*`; 7 lack `name`; 1 lacks
`job`; **22** have none of the four — 17 with no keyword at all (one-shot narration or scripted
scenes, the player 1801, five of the six prop talkers) and 5 with `y`/`n` only. [HIGH counts]

**8.1 Wildcard fallback = topic libraries on page 0x08.** In 96 of the 109 `*` branches the next
statements call page-0x08 routines in sequence, each `R08xx(A30)` returning True when one of its
own `match` lines hit (and having printed the answer) or False (0809 @0003 `match dim,light else
-> 004E`, `@0047 return True`, `@05AB return False`). 0801 (37 keywords: houses, rulers, cities —
`atti`, `thur`, `iron,mine`…) is called by 91 segments — the world lore every NPC knows; 0802–0811
and 0817 are smaller regional/factional sets (0809 Land King Hall, 0805 the Parium/Apis/Crito
group, 080C/0810 the 186E–1877 group, 080F the 1878–187C group …), 0812 a y/n helper, 0813/0816
no keywords.
Each library is a flat chain `match … text … return True`. [HIGH for the mechanism and counts;
MED for the regional labels, read from first keywords only]

**8.2 Common branch idioms** (corpus, MED as generalisations, HIGH per cited site):
- name → `setbit(A30,7)` (95 talk methods set bit 7; 45 test it).
- party NPCs: `join` → `join_party(A30)`; `wait` → `leave_party(A30)` + `activity = 112`;
  `foll` → `join_party` if `activity == 112` (1862 @02E3–0383). All 26 join/leave calls are
  **statement form** — the result (1 = party mode 2, 2 = party full, script-builtins B9) is
  discarded, and no talk script compares `G06:party_size` before joining, so a ninth recruit
  agrees but does not join. [HIGH discard; MED consequence]
- quests: `add_to_do`/`done_to_do` (41/29 in talk), `give_item` (23), `remove_items` (9),
  `who_in_party_has` (29), XP via R0E8B, training via R0EB1 (`pick_item` of skills).
- scripted scenes inside talk: `queue_activity` + `wait_for_flag` + `conversation_cue_1/2`
  (1802 @14AB–1599: NPC walks, conversation waits on flag 254). [HIGH bytes; LOW for what the cues
  do — EA/EB glue unread, script-builtins §4]

## 9. Knowledge gates

**9.1 Per-character bits = CharEntry +8.** Field 0x13 is `PTR_DAT_100cdbf0[sVar4 * 0x20 + 8]`
(`GetField__Fsss @ 100921b4`, case 0x13); helpers 0F00 setbit / 0F01 clrbit / 0F02 tstbit / 0F13
inparty operate on it (`0F02 @0009 return ((L00.f13:flags & (1 << A31)) != 0)`,
`0F13 @0009 return (L00.f13:flags & 64)`). [HIGH]
- **bit 7 = name known**: `GetCharacterName @ 10007d40` shows the 0x0201 name only
  `if ((param_3 != '\0') || ((PTR_DAT_100cdbf0[id * 0x20 + 8] & 0x80) != 0))`, else the tile name
  ("guard", "man"…). Writing field 0x13 calls `UpdateCharName(conv, id)` (SetField case 0x13), so
  the portrait label changes the moment `name` is answered. [HIGH] ⚑ corrected (wave 1 2026-10-03):
  the call has no null test (`_UpdateCharName__13TConversationFs(*_DAT_100cdcc8,param_1);`, unlike
  the guarded `RedoStat` above it), the TConversation dtor zeroes that global (`ppcdis.py --func
  '__dt__13TConversation'`: `1003b28c: 80828a48  lwz r4,-30136(r2)  ; TOC 0x100cdcc8`, `1003b298:
  90040000  stw r0,0(r4)`), and `UpdateCharName` reads `this+0xa4e`/`+0xa48` unguarded — so a 0x13
  write outside a conversation reads low memory 0xA48–0xA4F. [HIGH code; not observed on screen]
- **bit 6 = in party** (native, rules.md §2 RebuildParty). [HIGH]
- **bits 0–5 = script state** per character (quest stage, "asked already", "cured"): talk methods
  touch bit 1 ×40, 2 ×20, 0 ×10, 3 ×7, 4 ×5, 5 ×1 (self). The same bits are schedule conditions
  0x40–0x5F (rules.md §3). [HIGH counts; MED meaning]
- **Other characters' bits**: `R0F02(4, 3)` / `R0F00(4, 3)` in 1804 @079A/@0964 — cross-NPC
  knowledge ("has X been told"). Listed per method in the catalogue. [HIGH]

**9.2 Global state**: flags `test_flag`/`set_flag` (256 bits) and byte variables
`get_variable`/`set_variable` (32 bytes) — the same stores schedules read (script-builtins DC–DF);
karma G0C (`inckarma`/`deckarma` 0F12/0F11, 4 talk calls); item possession `who_in_party_has`;
`has_ability`; the NPC's `activity` (working hours); `leader_can_see` (party member present). [HIGH]

**9.3 Where the gate sits.** Of 1 325 talk `match` statements, **297** are immediately followed by
a conditional jump (routine call 119 — mostly the `*` library chain; self bit 53; byte variable 35;
other char's bit 29; local 23; inparty 17; global flag 12; activity 8); only **5** keywords are
gated *before* the `match` (`jf <cond> -> <same else-target>`: 180C @0317 and 1878 @0769 item,
1816 @01B7 variable, 1827 @01DE activity, 184C @04B7 local). Cythera gates **answers**, not
keywords: every keyword can be typed at any time; state chooses the reply. [HIGH counts; MED
summary]

**9.4 Karma shows on the player's name.** `ShowPortrait__13TConversationFss @ 1003dba4`: for
character 1 the label colour is `0x21` if `_DAT_100d73f0 < 0`, `-(0x1f - g/6)` if `g < 0x60`,
else `0x1e`; `_DAT_100d73f0` is global 0x0C (karma, clamped 0..100 by SetGlobal, script-vm §8).
[HIGH code; MED for "karma" as the name of G0C]

## 10. Portraits: builtin A4 `show_portrait(a, b)`

`Builtin_A4 @ 10094258` → `ShowPortrait__13TConversationFss(conv, short(a), short(b))`. [HIGH]
- **a = character id** (an object argument works: the 28-bit untag of 0x4040nnnn keeps nnnn in
  the low short). The portrait drawn is `DrawPortrait(0x20, b*0x58+0xC, a, 0x24)`, i.e. portrait
  segment `0x87FF + a` (data-format §6.2). The label under it is `GetCharacterName(a, …, 0)` —
  subject to the name-known bit. [HIGH]
- **b = slot 0, 1 or 2**, stacked 0x58 px apart; the last slot drawn becomes the **speaking slot**
  (+0xA4E) beside which quoted speech appears (§2.3). `a ≤ 0` clears slot b and moves the speaking
  slot to the first occupied one (`while (… < 3 && slot[i] < 1) i++`). [HIGH]
- Conventions: TalkCommand puts the leader in 2 and the partner in 0 (§1.1); scripts add a third
  speaker in slot 1 (1802 @05AA `show_portrait(3, 1)`) or swap the speaker. Corpus: b = 0 ×139,
  1 ×54, 2 ×93; no call clears (a = 0 never occurs); ⚑ corrected (wave 1 2026-10-03): 238 of 286 calls are in
  talk-method bodies, 244 in talk regions incl. local subroutines (§0 command). [HIGH]

## 11. Ending a conversation

- Normal: the `bye` branch prints a farewell and `return`s; TalkCommand closes (§1.1). An empty
  line is `bye` (§3.1). A method without input simply returns after its narration. [HIGH]
- Post-bye content: some methods continue after the farewell with a `prompt "yn"` favour
  (1804 @079A–096D, gated on the other character's bit 3). [HIGH]
- `end_talking()` inside a talk/signal method closes the window early (1801 @09CC, followed by
  `teleport` and `raise 0, Nil` — the non-local exit unwinds every interpreter loop, script-vm §3).
  TalkCommand's own `EndTalking` then finds +0x34 = 0 and does nothing. [HIGH]

## 12. Barks (TBark) — NPC one-liners on the map

- Scripts bark by **writing field 0x26**: SetField case 0x26 →
  `*(uint *)(iVar7 + 0x40) = param_4; *(undefined4 *)(iVar7 + 0x44) = 0;` on the character's
  active monster (string VAddr, expiry 0). Example 1802 @0044 `setfield A30.f26:f26 = "Yum"` in
  the `spawned` method. Census: 46 writes; 44 located by context: spawned ×10, routines (page
  0x30/0x0C/0x0E/0x0D) ×16, room enter ×6, use/use_on ×8, signal ×1, unlabelled ×3. [HIGH]
- `ShowBarks__14TActiveMonsterFv @ 1004f234` walks the monster list: a bark that is set (≠ Nil)
  with expiry 0 is shown only when the monster is inside the view and its visibility cell is lit
  (`… + 0xc0c8) & 3) != 0`); `SetBark` returns `TickCount() + 0xf0` (**240 ticks = 4 s**); an expired
  bark is removed and the field reset to Nil. [HIGH]
- `SetBark__5TBarkFs5VAddr @ 100623c4`: **4 balloon slots** (lazily created), reuse the slot
  already owned by this character else the first free; none free → returns 0. `SetMessage @
  100620e8` wraps text wider than 0x70 px onto two lines (`StyledLineBreak`). `RemoveBark` on
  monster deletion (`__dt__14TActiveMonsterFv`). [HIGH] The balloon frame is chosen from the
  sign of the speaker's dx/dy to the leader (flags 1/2/4 → `FrameRgn`). [MED]
- ⚑ After the visibility block ShowBarks tests `if (*(uint *)(iVar16 + 0x44) < uVar7)`: a bark
  whose expiry is still 0 (NPC not visible, or no free balloon) is therefore **removed and reset
  to Nil on the same pass** — barks are not queued for later. [HIGH]

## 13. Conversation UI modes

All are `TConvMode` subclasses run by `TConvMode::Perform @ 1003ca28` (flush events, disable menu
0x81, run the modal loop, restore) and ended by `Done @ 1003cba0` (sets app +0x1C). Vtables from the ctor
stores (`*param_1 = &PTR_PTR_100d50d4;` etc.; ConvMore's `addi r0,r2,-372`), slots by the §0 one-liner,
names `tb.py --at` ⚑ corrected (wave 1 2026-10-03): [HIGH]

| class | vtable | started by | ends on |
|---|---|---|---|
| `TConvResponseMode` | 0x100d50d4 | `GetResponse` (0x8E, 0x8F, WhoWill) | Return/Enter in the text field; click on a chip; single-key choice (§3.3, §6) |
| `TConvMoreMode` (unlisted in the class map) | 0x100d510c | `ConvMore` at `*` | any key (Esc = skip later pauses); click (journal or continue) |
| `TPickMode` | 0x100d509c | `PickItem` (C0) | item (index) or button (−k−1) |
| `THowManyMode` | 0x100d4e98 | `HowMany` (B4) | slider value (controls 0x3e91 / 16000; mouse/key not read) |
| `TModalMode` | 0x100d4e60 | `CreateModal` | not read |

## 14. Catalogue of the 127 talk methods

Columns: **seg**; **name** (0x0201 via the listing header; props: tile name); **in** `input`; **br**
`match` statements / **w** words; **pr** `prompt`; **sp** `show_portrait`; **self t / s** CharEntry+8
bits of A30 tested / set-or-cleared; **other** `char:bit` on other characters; **flags** t/s =
test_flag/set_flag; **vars** g/s = get/set_variable; **builtins** JP join, LP leave, GI give_item, RI
remove_items, TI transfer_item, TP teleport, CP create_prop, DP delete_prop, AA add_answer, PI
pick_item, HM how_many, EG end_game, TD/DD add/done_to_do, AB ability, QA queue_activity, WF
wait_for_flag, ET end_talking, WH who_in_party_has, SS send_signal, CU curtain_picture, RS
reschedule; **08xx** topic libraries called. Scope: method + local subroutines only. [HIGH — ⚑
corrected (wave 1 2026-10-03): every column but per-row builtins re-derived from the §0 region set]

| seg | name | in | br | w | pr | sp | self t | self s | other | flags | vars | builtins | 08xx |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 102E | prop: guard | 0 | 0 | 0 | 0 | 1 |  |  |  |  |  |  |  |
| 104E | prop: corpse | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 10E5 | prop: guard | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 1114 | prop: metal door | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 111B | prop: corpse | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 1121 | prop: ghost | 1 | 7 | 11 | 0 | 1 |  |  |  |  |  |  |  |
| 1801 | Hero | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 1802 | Alaric | 1 | 25 | 28 | 0 | 3 | 1,2,7 | 2,7 |  | s0 | g0 | AA×2 AB CP CU×4 EG×2 GI PI QA×17 TD×2 WF×3 | 0801 0809 |
| 1803 | Magpie | 1 | 31 | 38 | 0 | 4 | 1,2 | 2,7 | 120:3,121:4,2:7 |  |  | GI |  |
| 1804 | Hadrian | 1 | 12 | 19 | 1 | 7 |  | 7 | 4:0,4:1,4:2,4:3,4:7,6:0 |  |  | AA GI PI TD×2 | 0801 0809 |
| 1805 | Emesa | 1 | 24 | 30 | 2 | 0 |  | 7 | 5:7 |  |  | GI | 0801 0809 |
| 1806 | Hector | 1 | 23 | 25 | 1 | 3 |  | 7 | 4:0,4:1,6:0,6:7 |  |  | AA×4 JP×4 LP×3 | 0801 0809 |
| 1807 | LKH Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 0809 |
| 1808 | Cademia Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 080E |
| 1809 | Ruins Guard | 0 | 0 | 0 | 0 | 2 |  |  |  |  | g7 s7 | ET×2 QA×7 TP×2 WF |  |
| 180A | Myus | 1 | 11 | 11 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 0804 080D |
| 180B | Naxos | 1 | 12 | 12 | 0 | 0 | 7 | 7 |  |  | g3 |  | 0801 0804 080E |
| 180C | Darius | 1 | 14 | 16 | 0 | 0 | 7 | 7 |  |  | g1,2 | WH | 0801 0804 080B |
| 180D | Pelagon | 1 | 9 | 10 | 2 | 5 | 0,1 | 0,1,7 | 108:2 |  | g3 | CU×2 EG GI RS WH×2 | 0801 0804 080D |
| 180E | Deiphobus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 180F | Kosha Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 080D |
| 1810 | Atreus | 1 | 9 | 10 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 080D |
| 1811 | Ennomus | 0 | 8 | 8 | 5 | 0 | 1 | 1 |  |  |  | GI HM |  |
| 1812 | Ariethous | 1 | 13 | 17 | 1 | 0 |  | 7 |  |  |  |  | 0801 080D 0813 |
| 1813 | Laodice | 1 | 10 | 10 | 1 | 0 | 7 | 7 |  |  |  |  | 0801 080D |
| 1814 | Thuria | 1 | 11 | 13 | 2 | 14 | 1,2,7 | 1,2,7 | 121:7,23:1,29:1 |  |  | DD TD | 0801 0802 080E |
| 1815 | Malis | 1 | 9 | 10 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 0802 080E |
| 1816 | Cybele | 1 | 8 | 9 | 0 | 0 | 7 | 7 |  |  | g3 |  | 0801 0802 080E |
| 1817 | Amphidamas | 1 | 10 | 11 | 0 | 0 | 1,7 | 1,7 | 20:1 |  |  |  | 0801 0811 |
| 1818 | Eurybates | 1 | 5 | 9 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 0811 |
| 1819 | Rhesus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 181A | Lycurgus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 181B | Erechtheus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 181C | Thamyris | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 181D | Atymnius | 1 | 6 | 7 | 0 | 2 | 1,7 | 1,7 | 20:1 |  |  |  | 0801 0811 |
| 181E | Milcom | 1 | 19 | 28 | 1 | 2 | 1,7 | 1,7 |  |  | g2 | TD | 0801 0803 080A |
| 181F | Sardis | 1 | 13 | 13 | 0 | 0 | 7 | 7 |  |  | g2 |  | 0801 0803 080B |
| 1820 | Ake | 1 | 13 | 17 | 1 | 2 | 1,2,7 | 1,2,7 |  |  |  | TD×2 | 0801 0803 080A |
| 1821 | Neoptolemus | 1 | 35 | 41 | 1 | 0 | 0,7 | 0,7 |  |  |  | PI | 0801 080E |
| 1822 | Meleager | 1 | 25 | 25 | 5 | 6 | 0,1,7 | 7 | 34:0 |  |  | AA×3 JP×3 LP×2 | 0801 |
| 1823 | Hebe | 1 | 11 | 15 | 1 | 2 | 1,2 | 1,2,3,7 | 36:1,41:3 |  |  |  | 0801 080A |
| 1824 | Antenor | 1 | 12 | 14 | 2 | 2 | 1,2 | 1,2,7 | 35:1 |  |  | GI | 0801 080E |
| 1825 | Alastor | 0 | 2 | 2 | 1 | 0 | 1,2,7 | 1,2,7 |  |  | g8 s8 | DD GI RI TD WH×2 |  |
| 1827 | Eioneus | 1 | 12 | 13 | 2 | 0 | 1,7 | 1,7 |  |  |  | DD DP PI | 0801 0808 |
| 1828 | Parium | 1 | 22 | 26 | 5 | 2 | 0,1,2 | 0,1,2,7 |  |  | g4 s4 |  | 0801 0805 080B 0812 0813 |
| 1829 | Crito | 1 | 23 | 27 | 5 | 6 | 0,1,2,3,4 | 0,1,2,3,4,7 | 35:3 |  | g4 s4 |  | 0801 0805 080A 0812 0813 |
| 182A | Apis | 1 | 26 | 32 | 7 | 4 | 2,3,4,5,7 | 2,3,4,5,7 |  |  |  | DD GI RI TD×2 WH | 0801 0805 080E 0812 0813 |
| 182D | Dares | 1 | 14 | 15 | 2 | 0 |  | 7 |  |  |  |  | 0801 0805 080E 0813 |
| 182E | Diomede | 1 | 15 | 17 | 2 | 0 |  |  |  |  |  |  | 0801 0805 080E 0813 |
| 1830 | Thetis | 1 | 9 | 10 | 0 | 0 |  | 7 |  |  |  |  | 0801 0802 080E |
| 1831 | Bias | 1 | 8 | 9 | 0 | 0 |  | 7 |  |  |  |  | 0801 0802 080E |
| 1832 | Philinus | 1 | 19 | 19 | 0 | 6 | 0 | 0,1,7 | 55:1,55:2 | t3 | g1,2,3 s1 | DD GI LP QA×18 RI WH×2 | 0801 0806 080A |
| 1833 | Opheltius | 1 | 9 | 9 | 0 | 0 | 1,7 | 1,7 |  | t3 | g1 |  | 0801 0806 080E |
| 1834 | Ascalon | 1 | 14 | 17 | 1 | 0 | 7 | 7 |  | t3 | g1,3 |  | 0801 0806 080A |
| 1835 | Ariadne | 0 | 2 | 2 | 1 | 0 |  | 7 |  |  | g1 s1 | JP |  |
| 1836 | Odemia Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 080A |
| 1837 | Tlepolemus | 1 | 20 | 25 | 2 | 2 | 0,1 | 1,2,7 | 50:1 |  |  |  | 0801 080A |
| 1838 | Eteocles | 1 | 17 | 20 | 1 | 4 |  | 7 | 72:1 | t4 s4 | g3,4 | GI PI TD | 0801 080E |
| 1839 | Laomedon | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 183A | Ilus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 183B | Autonous | 1 | 8 | 10 | 0 | 0 |  | 7 |  |  |  |  |  |
| 183C | Propontis | 2 | 17 | 19 | 1 | 0 | 7 | 1,7 |  |  | g1,2 | TD | 0801 0807 080B |
| 183D | Mantinea | 1 | 11 | 12 | 0 | 0 |  | 1,7 |  |  | g2 |  | 0801 0807 080B |
| 183E | Halos | 2 | 29 | 30 | 0 | 10 | 1,2,3,4 | 1,2,3,4,7 | 32:1,60:1,61:1 |  | g1,3 | DD×4 RI WH×2 | 0801 0807 080E |
| 183F | Catamarca Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 080B |
| 1840 | Oeneus | 1 | 6 | 7 | 0 | 0 |  | 7 |  |  |  |  | 0801 080E |
| 1841 | Periphas | 0 | 2 | 2 | 1 | 2 | 1 | 1 | 42:3 |  |  | GI TD |  |
| 1842 | Theano | 0 | 2 | 2 | 1 | 0 |  |  |  |  |  |  |  |
| 1843 | Hypsenor | 1 | 7 | 8 | 0 | 0 |  | 7 |  |  |  |  | 0801 080E |
| 1844 | Thoas | 1 | 8 | 8 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 080E |
| 1845 | Dymas | 1 | 8 | 11 | 1 | 0 | 1,7 | 1,7 |  |  |  |  |  |
| 1846 | Sacas | 1 | 19 | 23 | 3 | 22 | 0,1,3,4,7 | 0,1,2,3,4,7 | 101:0,94:0,94:1 | t3 | g1,12,13,14,15,16 | AA DD×2 GI TD×2 | 0801 0808 080A 0817 |
| 1847 | Metopes | 1 | 18 | 21 | 0 | 6 | 7 | 7 |  |  | g2 s2 | DD TD×2 | 0801 0808 080B 0817 |
| 1848 | Berossus | 1 | 12 | 13 | 0 | 30 | 1 | 1,7 | 108:3 |  | g3 s3 | DD×2 LP RS TD×2 | 0801 0808 080E 0817 |
| 1849 | Itanos | 1 | 13 | 15 | 1 | 0 | 1,2 | 1,2,7 | 75:1 | s66 |  | GI×2 TD×2 | 0801 0808 080D 0817 |
| 184A | Timon | 1 | 20 | 27 | 0 | 6 | 1,7 | 7 |  | t2 | g2,7 s2,7 | AA×3 DD GI JP×2 LP×2 WH | 0801 0808 |
| 184B | Prusa | 0 | 0 | 0 | 0 | 0 | 2 | 2 |  |  |  | DD GI |  |
| 184C | Bryaxis | 1 | 11 | 11 | 1 | 2 |  | 7 | 76:7 |  | g4 s4 |  | 0801 0808 080E |
| 184D | Anisa | 1 | 34 | 35 | 3 | 2 | 1,2,7 | 1,2,7 | 2:2 |  |  | DD TD | 0801 0808 080E |
| 184E | Pheres | 1 | 13 | 16 | 2 | 0 | 1,2 | 1,2 | 78:7 |  |  | DD RI TD WH×2 | 0801 0808 080C |
| 184F | Charax | 1 | 7 | 7 | 0 | 24 |  | 3,7 | 102:7,79:1,79:2,79:3,79:4,79:7,82:0 |  | g3 | DD×2 QA×2 RI×3 TD×2 WF WH×4 | 0801 0808 |
| 1850 | Lindus | 1 | 20 | 25 | 1 | 0 |  | 7 | 70:1,70:2,80:7 | t1 s1 | g2 s2 | DD×3 GI×2 PI×2 TD×3 WH | 0801 0808 080C |
| 1851 | Selinus | 1 | 19 | 22 | 2 | 0 | 2 | 2,7 | 79:7,81:7 |  | g5,6 s5,6 | DD RI TD×2 WH×2 | 0801 0808 080C |
| 1852 | Palaestra | 1 | 12 | 14 | 0 | 4 |  |  | 102:7,70:1,82:0,82:7 |  |  |  | 0801 0808 080C |
| 1853 | Tros | 1 | 8 | 11 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 0808 080C |
| 1854 | Pnyx Guard | 1 | 3 | 3 | 0 | 0 |  |  |  |  |  |  | 0801 080C |
| 1855 | Alcestris | 1 | 8 | 9 | 1 | 0 | 7 | 7 |  |  |  |  | 0801 080E |
| 1856 | Asius | 1 | 4 | 4 | 0 | 0 | 7 | 7 |  |  |  |  | 0801 080E |
| 1857 | Paris | 1 | 7 | 8 | 0 | 2 |  |  |  |  |  |  | 0801 0805 080C |
| 1858 | Helen | 1 | 15 | 17 | 2 | 0 |  | 7 |  |  |  |  | 0801 0805 080C 0813 |
| 1859 | Niobe | 1 | 8 | 12 | 0 | 4 | 1,7 | 1,7 | 88:7 |  |  |  |  |
| 185A | Larisa | 1 | 11 | 11 | 0 | 6 |  | 7 |  |  | g7 s7 |  | 0801 |
| 185B | Joppa | 1 | 7 | 7 | 1 | 2 | 7 | 7 |  |  |  |  | 0801 0804 |
| 185C | Eudoxus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 185D | Eumelus | 1 | 10 | 10 | 1 | 0 |  | 7 |  |  | g2 | HM | 0801 080B |
| 185E | Antiphus | 1 | 9 | 13 | 0 | 0 | 7 | 1,7 |  | t3 | s1 |  |  |
| 185F | Polydamas | 1 | 11 | 12 | 1 | 0 | 1 | 1,7 | 95:7 |  | g2 |  | 0801 080B |
| 1860 | Peirithous | 1 | 6 | 6 | 0 | 0 |  | 7 |  |  |  |  | 0801 080A |
| 1861 | Aethon | 1 | 20 | 30 | 1 | 2 | 1 | 1,7 | 62:3 |  | g3 | JP | 0801 080E |
| 1862 | Dryas | 1 | 15 | 16 | 2 | 0 | 1,7 | 0,1,7 |  |  | g3 | AA×3 JP×4 LP TD×3 | 0801 080E |
| 1864 | Gate Guard | 2 | 13 | 15 | 1 | 2 |  |  |  | t3 s3 | g1 s1 | SS×3 TD WH | 0801 080A |
| 1865 | Thersites | 1 | 9 | 11 | 0 | 4 | 0,1,2,7 | 0,1,2,7 | 70:0,70:1 | t3 | g1 | DD×2 GI PI TD TI×2 WH×4 | 0801 080A |
| 1866 | Glaucus | 1 | 14 | 15 | 0 | 0 | 7 | 7 |  |  |  |  |  |
| 1867 | Borus | 1 | 8 | 9 | 0 | 9 | 1,7 | 7 | 102:7,103:1,104:1 |  |  |  | 0801 |
| 1868 | Briseis | 1 | 9 | 11 | 0 | 0 | 1,7 | 7 |  |  |  |  | 0801 |
| 1869 | Pelops | 1 | 11 | 13 | 2 | 0 | 7 | 7 |  |  |  |  | 0801 |
| 186A | Alcmena | 1 | 15 | 15 | 2 | 0 | 7 | 7 |  |  |  |  | 0801 |
| 186B | Asteropaeus | 0 | 0 | 0 | 0 | 0 |  |  |  |  |  |  |  |
| 186C | Stentor | 1 | 10 | 11 | 0 | 10 | 1,3 | 1,2,3,7 | 73:1 |  | g3 | DD TI WH×2 | 0801 080D 080E |
| 186D | Demodocus | 1 | 37 | 58 | 0 | 0 | 0,7 | 0,7 | 20:1 |  | g4 s4 | TD | 0801 080E |
| 186E | Thrasymedes | 1 | 6 | 6 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 186F | Protesilaus | 1 | 6 | 6 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C |
| 1870 | Menelaus | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1871 | Lycaon | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1872 | Peleus | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1873 | Peisander | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1874 | Danae | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1875 | Semele | 1 | 6 | 6 | 0 | 0 |  | 7 |  |  |  | TD | 0801 0808 080C 0810 |
| 1876 | Alcyone | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1877 | Clytemnestra | 1 | 5 | 5 | 0 | 0 |  | 7 |  |  |  |  | 0801 0808 080C 0810 |
| 1878 | Sabinate | 1 | 14 | 20 | 1 | 2 | 4 | 7 | 120:1,120:2,120:3,120:7,34:1,74:1 |  |  | GI×2 TD×2 WH×2 | 080F |
| 1879 | Jhiaxus | 1 | 11 | 11 | 1 | 8 |  | 7 | 121:1,121:2,121:3,121:4,121:7,34:1,74:1 |  |  | DD×2 TD |  |
| 187A | Unhayt | 1 | 6 | 9 | 0 | 1 | 1 | 1,7 |  |  |  | GI | 080F |
| 187B | Seqedher | 1 | 6 | 8 | 0 | 1 |  | 7 |  |  |  |  | 080F |
| 187C | Uset | 1 | 5 | 7 | 0 | 1 |  | 7 |  |  |  |  | 080F |
| 187D | Ignae | 1 | 30 | 32 | 0 | 2 | 7 | 7 | 120:7,121:7 |  |  |  |  |
| 187F | UrSylph | 1 | 24 | 31 | 0 | 0 | 7 | 7 |  |  |  |  |  |

Totals: 127 methods (121 characters = every page-0x18 class + 6 prop types); `input` 108;
`match` 1 325 (1 551 words); `prompt` 88; QA 44, TD 41, WH 29, DD 29, GI 23, AA 17, JP 15, LP 10,
RI 9, PI 8, CU 6, WF 5, EG 3, SS 3, TI 3, ET 2, TP 2, RS 2, HM 2, CP 1, AB 1, DP 1. [HIGH]
A `0` in **in** with non-zero **br** means the keywords follow `prompt "yn"` only (1811, 1825,
1835, 1841, 1842). Bits 0–5 are tested in other methods too (signal, spawned) — not counted here.

## 15. Open items

1. The 0816 "Where Is" row fields and the `"%p%s"`/`"%s"` pick_item formats (Builtin_C0,
   `TPickItemDrawer` not read).
2. TConvResponseMode Draw/Idle, THowManyMode input, TModalMode, TSimpleInteraction.
3. TTextContext `<d`, `>`, `&` codes; whether hint runs are drawn differently.
4. What `IsJournalable`/`WriteJournal` record on a click (TJournal).
5. ⚑ corrected (wave 1 2026-10-03) Not yet observed on screen (behaviour check): the byte dropped
   before `*` (§2.4), the unterminated ≥ 64-char input (§3.3), the 0x13 write outside a talk (§9.1).
6. EA/EB `conversation_cue_2/1` (unnamed glue).
7. Quest meanings of CharEntry+8 bits 0–5, global flags and byte variables used by talk methods.
8. Whether the Talk command checks `CanTalk` first; native callers of `TConversation::mygetnum`.
