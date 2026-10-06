# Cythera 1.0.4 RE wave 2 — review (2026-10-06)

⚑ wave 2 (2026-10-06) — reviewer report. Scope: `git diff 0444b1c..HEAD -- docs/cythera/` (census d1cae64 +
b03748b, 16d91fd, 57ae2a3, 3dd7c6e, 23caf13). Every claim in the table of §2 was re-derived this session with
the banked tools from the worktree root (`$S` = session scratchpad; `$S/all.dis` =
`python3 docs/cythera/tools/ppcdis.py 10000000 100cd280`, 212,074 lines). No bank file was edited.

## Verdict: **ACCEPT_WITH_FIXES**

0 Critical · 3 Major · 13 Minor · 9 Notes. 84 claims re-derived, 82 PASS, 2 FAIL (both Minor/Major label or
side-evidence issues; no closure is overturned). Hazard sweep clean: no stray `--help` file
(`ls -la | grep help` → nothing), no `ppcdis.py` call on an address ≥ 0x100CD280 in the diff, every
`find_func.py` in the diff passes `--file`; the diff deletes no wave-1 text (every `-` line reappears with a
`⚑ wave 2` suffix); file sizes within limits (largest bank combat.md 616, ui-play.md 516, ui-toolkit.md 203,
census 252); no "a replica must…"; notes files ≤ 200 words before the INDEX block (137–194).

## 1. Findings

### Critical
None.

### Major
**M1 — rules.md §3.4 still states the overturned 0x80 condition, unmarked** (confidence HIGH).
rules.md:101 "old visible (monster exists): keep position, set waypoint (walks there); activity → 0x80".
Ran `ppcdis.py 100064a0 10006680` (r19 = `IsVisibleAbs` of the prop's current location at 10006564/1000657c;
r23 = `IsVisibleAbs` of the new location at 1000659c/100065b0) and `ppcdis.py 10006680 10006740`:
old visible → `100066a4: stb r25,22(r31)` (target activity); old not visible, new visible, monster →
`10006724: li r0,128 / 10006728: stb r0,22(r31)`. open-items §3.2 is right; rules.md is wrong and carries no
⚑ marker (outside R5's write set, listed in open-items §10). Fix (orchestrator): append
`⚑ wave 2 (2026-10-06): superseded — 0x80 is the old-not-visible → new-visible case (open-items-2026-10-06.md §3.2)`.

**M2 — quests-flags.md §10 item 2 repeats the inverted ending mapping, unmarked** (confidence HIGH).
quests-flags.md:448 "What makes the frame-6 crystal's quality non-zero (damned ending), §5." R5 superseded
step 12 and the §5 paragraph in the same file but left this open-list line. Verified the new reading:
`1025.txt` `0445 jf (A30.f06:quality == 0) -> 0458`, `044F set_variable(0, 2)`, `0458 set_variable(0, 1)`;
`1802.txt` `02F8 jf (get_variable(0) == 2) -> 0539`, `050A end_game(damned)`, `06E3 end_game(saved)`. Fix: mark
item 2 `⚑ wave 2: closed — non-zero quality is the saved ending (§5, open-items-2026-10-06.md §7)`.

**M3 — "an idle turn every 1/3 s" is labelled HIGH with no bank evidence for what space does** (confidence
MED on the defect; the reading is probably right). engine-classes.md §3.4 ("fabricates a space keyDown … an
idle turn every 1/3 s. [HIGH]"); app-shell.md §2.3 defers the meaning to "the map window's (ui-play.md)", but
ui-play.md does not cover `KeyRoutine__10TMapWindowFs` (extra dump, not group D) — the cross-ref dangles.
Ran `find_func.py 'KeyRoutine__10TMapWindowFs' --file ghidra/Cythera_extra.decompiled.c`: key 0x20 →
`ScheduleKeyDown(win, key)` when the window kind word is 3; then `KeyRoutine__16TDroppableWindowFs @ 1002a07c`
(main dump, `LAB_1002a3a4`): key target active → its slot +8 (stop); else `KeyboardMode(0)` +
`XDirection__16TDroppableWindowFQ28TGameSys10EDirection(win, 8)`. Fix: cite that chain and either trace
`XDirection(…, 8)` (direction 8 = stand still?) to lift it, or label the "turn" reading MED.

### Minor
**m1 — open-items §5: `ColorCycle` "with no `bl` caller" is false** (HIGH). `grep 'bl 0x10008694' $S/all.dis`
→ `100432c4: bl 0x10008694` in `AnimThread__10TMapWindowFPv` (tb.py; m:10846 `_ColorCycle__FP8GrafPort(…)`),
i.e. called every animation frame; app-shell §3.1 and ui-play §5.3 say so. The conclusion (cycling stubbed
out: `10008694: 4e800020 blr`) and the F005 no-reader closure stand. Fix the sentence.
**m2 — D4 row: two argument-counting conventions side by side** (HIGH; resolves the seat-spotted
inconsistency). It is the same argument: `PlaySound__6TAudioFUsssUcUc(this, id, dx, dy, param_5, param_6)`;
param_5 = wait flag (D3 passes 0, D4 passes 1 — `…,iVar6,iVar4,1,uVar2)` in `cbPlaySoundSync`), param_6 =
`far`, halves both stereo levels. Wave-1 "4th argument" counts without `this` (as the D3 row's
`PlaySound(id, x−lx, y−ly, 0, far)` does); census §2 and the wave-2 append say "5th" counting `this`. Fix:
write "param_5 (4th after `this`)" in script-builtins.md §3.
**m3 — data-format §8.2 "0.5–0.2 … read only by `MyScheduler`"** (HIGH). PostInitMac also reads it:
m:4384 `bVar1 = DAT_100d3e20 >> 2 & 0xf;` (check marks 10/11/12, inside the dead `GetMenuHandle(0x88)` block).
Fix: "read by MyScheduler (and PostInitMac's unreachable check-mark block)".
**m4 — engine-classes §3.4 "in practice F = 6: 10 frames/s"** (HIGH). `MyScheduler` (m:5660–5785) only
enforces a minimum spacing (`next += F` / `next = now + F`, frames run only when no event, redraw, task slice,
conversation or background state takes precedence). 10 fps is an upper bound. Wording: "at most 10".
**m5 — app-shell §8 / §4.1 imply a menu-bar "Strategy" route to `EditUserBehaviors`** (HIGH). MBAR 129 = [135] is
inserted with `CreateMenu(id, -1)` (hierarchical, not in the bar: `TCommandMenu::CreateMenu @ 1000f6e4` →
`InsertMenu(…, param_2)`); the only `bl 0x100b1b38` is `1002f390` in `TCharacterWindow::MouseRoutine`
(ai-scripts §9.1 scan, re-run). MENU 135 is the popup's menu (CNTL 135, ui-toolkit §1). Fix wording.
**m6 — app-shell §5.1 "releases the background PICT seven times"** (HIGH). `ppcdis.py 10017180 1001722c`: one
release, then loop `cmpwi r0,6 / blt` releasing +0x94 once per **non-NULL** frame slot → up to seven.
**m7 — unbanked scripts and elided commands** (HIGH as register defect; evidence itself holds).
open-items rests on `$S/r5props.py`, `$S/r5scan7.py`, `$S/clr80.txt` (session scratch, not in tools/) and shows
`python3 -c "…seg.toc(); o,l=s[0xF008]; raw=d[o:o+l]; …"` (§2.1, §5) with the body elided; app-shell §0 elides
its classifier heredoc and uses an unbanked "helper that walks ppcdis.py output". I re-implemented the prop
decoder from open-items' prose and reproduced item 5 exactly (40 levels, kind 0 12104 / 0x11 55 / 0x42 879 /
0x80 52; 21 owners; levels 3,6,8,11,13,17,24; byte 6 = 0, frame 0). Fix: bank the decoder or inline it.
**m8 — quote density** (LOW–MED; depends on whether UI/engine labels count as game text).
scripted-windows §4.1 quotes seven button titles; app-shell §1.1/§1.3/§4.2/§5.1–5.2 quote several engine
strings per section; open-items §7 quotes an `end_game` line plus a hintbook line (documentation, 10 words).
**m9 — no enumerated coverage list in dialogue-ui.md / scripted-windows.md** (HIGH). ui-play/app-shell/
ui-toolkit list every address; these two say "all 71 / all 128 read whole". By-name sweep (census classifier
re-run → `E.txt` 71 rows / 15,788 B): every E body is named in prose; for F, ~60 small bodies
(`Marshal`/`Draw`/`GetField`/stubs) are covered only collectively. Add the address lists.
**m10 — census §1 C row: `MyScheduler` "spaces turns by …"** (HIGH). It spaces animation frames (engine-classes
§3.4, verified m:5753/5756). Triage wording only.
**m11 — open-items §8: "strange device 1175 use → sub_0063(…)"** (HIGH). `1175.txt`: `use@0225` builds the
window and sets `f39 = @01FB/@0209/@0217`; the sends come from those handlers (`01FE callsub sub_00BE(A30,0)` …)
via `TWPixButton::MouseRoutine` — as scripted-windows §7 says. Wording.
**m12 — dialogue-ui §9 "reachability HIGH by the grep"** (LOW). The grep covers string literals; pick_item
button lists could carry runtime-built strings (`sysnew_03` concatenation). MED fits better.
**m13 — app-shell §4.3 Party menu "item n ≥ 3"** (HIGH, nit). `DefaultMenu` m:4976: any item ≠ 1 takes
`table[n − 3]` (item 2 is the separator, so unreachable).

### Notes
**N1 — cross-file lifts available.** (a) dialogue-ui §8 "0x110/0x113 … source not traced" = Home/End from
`TApp::TranslateKey @ 1000d030` (p:3150–3170 `case 0x73: 0x110` … `case 0x77: 0x113`; ui-toolkit §3.1).
(b) scripted-windows §10 "0x3E90 WDEF's use of the refCon": 0x3E90 = 16016 = WDEF 1001 var 0 = `TPixsWDEF`
(ui-toolkit: refCon hi word = pix id, byte 1 = x, byte 0 = y), matching `DisplayPicture`'s `a3 | a1<<16 |
a2<<8`. (c) ui-play §10 item 3 `(param_4 & 3) >= 2` is very likely TaskThread's coalesce mark (app-shell §3.2,
m:5869 `uStack_90 & 0xfffffffc | 2`). (d) THowManyMode slider proc 0x3E91 = CDEF 1001 var 1 = `TProgBarCDEF`,
which prints the control's refCon on the knob — matches `SetValue` writing the refCon.
**N2 — D4 stalls the whole program, not only the script** (MED). The `PlaySound` wait loop has no yield; under
the cooperative Thread Manager the event loop and anim thread do not run until the voice leaves the table.
**N3 — owed cross-file updates (orchestrator):** INDEX NOT RESOLVED list; data-format §4.3 kind-0x11 row and
§5 F005/F007 row; open-items-2026-10-03 PORT row; combat.md §16.4 (scoped "combat routines read here" — not
wrong, add a pointer to open-items §2.3).
**N4** — scripted-windows §7 lists script-only signals as 1, 34, 35, 130, 135; 100+frame (half disk 10E8) is
script-only too.
**N5** — `TAudio::Init` reads "Music" with code default **8** (p:6948 `GetOrdinal(…,0,8)`) while data-format §8.1
gives music 0..3; unexplained (Pref 129 "Music" = 2 normally answers first).
**N6** — ui-toolkit §3.2 assigns the title key map to "DLOG 128–139, 141"; the filter is `MyAlert`'s
(`GetNewDialog` + `*_DAT_100cdde8`). DLOG 133 (`TCreatePlayerDialog`) title `;;Mm;Fm` would map M→item 3,
F→item 4, not the Male/Female radios 5/6 — suggests DLOG 133/141 titles are not consumed by it. LOW.
**N7** — `TDelverApp::TranslateKey` maps ⌘1–⌘9 to 0x100–0x108, the same codes `TApp::TranslateKey` gives
F1–F4 (0x100–0x103; `TWindow::KeyRoutine` → undo/cut/copy/paste). Routing between them not reconciled. LOW.
**N8** — open-items §1 cites `callx` statement offsets (0C00@0010, 0C43@0003, 0816@007C, 0EA5@003B);
script-vm.md cites the 0x9C opcode offsets (@0011/@0004/@007E/@003D). Same four sites.
**N9** — engine-classes/app-shell: `MyScheduler`'s first block re-tests `next == 0` each call (not "first call
only"); harmless since `next` never returns to 0.

## 2. Claims re-derived

| file | claim | command (abridged) | result |
|---|---|---|---|
| census §4 | 95 opcode→name→addr rows | brief `join` → 95; diff vs table | PASS (identical) |
| census §2 | item 14: no TVector for PerformAI/CompileAIFile/EditUserBehaviors | `toc.D` word scan incl. absolute | PASS (only 0x100d05c8 RangeIter) |
| census §2 | item 16: m:5715 spin, m:5756 `+ (DAT>>2&0xf)` | `sed -n 5655,5790p` missing dump | PASS |
| census §2 | CPU default words | `toc.data_u32(0x100d426c,4)`; `toc.py 100d4270 …` | PASS |
| census §2 | item 19 param_5 wait loop | `find_func.py 'PlaySound__6TAudioFUsssUcUc' --file pef` | PASS |
| census §2 | N3 totals | census python on `$S/all.dis` | PASS (89; −1×5, 0×3 …) |
| census §1 | popup → +0x1E = v−0x53 | m:7290–7310 | PASS |
| census §1 | idle space keyDown after 0x14 ticks | m:4546–4614 | PASS |
| app-shell §3.3 | prefs read is byte 0 bits 2–5 | `ppcdis.py 1001cb94 1001ced8` (`lbz r0,0(r26)`, `rlwinm r0,r0,30,28,31`) | PASS |
| app-shell §4.3 | items 10/11/12 `&0xc3 \| 0x10/0x18/0x20` | m:4949/4955/4961 | PASS |
| app-shell §4.3 | MENU 136 labels; 6/7/8 = Smoother/Faster/Fastest | `rsrc.parse` MENU dump | PASS |
| app-shell §4.3 | 0x83/0x88 never inserted | grep `InsertMenu\|GetMenu(` 4 dumps; MBAR 128=[128,129], 129=[135]; `CreateMenu` callers | PASS (MED absence stands) |
| app-shell §5.1 | CloseRoutine releases +0x94 not frames | `ppcdis.py 10017180 1001722c` | PASS (m6 nuance) |
| app-shell §6 | `ReadTo` copies into &len | `ppcdis.py 10018664 100186c0` (`mr r4,r31` = r5) | PASS |
| app-shell §1.1 | 0x78-tick splash wait unless byte 3 bit 0 | `ppcdis.py 100176c0 10017700` | PASS |
| app-shell §2.3 | flag 0x100cdd04 init 0, toggled by key 0xCA | `toc.D[0x62604:0x6260c]`; x:619; `-30076(r2)` 4 loads | PASS |
| app-shell §2.3 | space → "passes a turn" | x: KeyRoutine → ScheduleKeyDown → p: `XDirection(8)` | FAIL label (M3) |
| app-shell §7 | `GetOrdinal` bound `size>>2 <= idx+1`; defaults 5/8/1 | p:4054–4070, p:6946–6950 | PASS |
| app-shell §3.2 | kind 4 FindSkill/0x3FFF/HeartBeat(3); kind 1 low bits := 2 | m:5793–5911 | PASS |
| app-shell §0 | 125 rows / 30,876 B, all addresses listed | census classifier + regex; grep each addr | PASS |
| engine-classes §3.2⚑ | 0x100ce898 budget never read | `grep -- '-27112(r2)'` (3 loads, all MoveAll); TOC alias scan | PASS |
| engine-classes §3.2⚑ | 0x3C guard → flag → FlushEvents(0x2a) on exit | p: MoveAll body | PASS |
| engine-classes §3.4 | DoTick/Guide set mode 3 + YieldToAnyThread | p:21320, p:21461 | PASS |
| engine-classes §3.4 | Render/HandleMove/HandleSubMove have no waits | grep Render body p:32113–33455 → 0 | PASS |
| engine-classes §3.4 | transition wait 5 ticks | p:28009 | PASS |
| engine-classes §3.4 | "10 frames/s in practice" | scheduler body | PASS as bound (m4) |
| data-format §8.2 | movement bits ↔ MENU 136 items | DefaultMenu + MENU 136 | PASS |
| data-format §8.2 | 0.5–0.2 read only by MyScheduler | `grep 'd3e2'` | FAIL (m3: m:4384) |
| data-format §8.2 | 1.6 MoveCommand, 1.3 DisplacementFilterTile | find_func greps | PASS |
| data-format §8.3 | four words decode (F = 6 each) | arithmetic on 0x18/0x99/0xDB, 0x80/0xC8 | PASS |
| data-format §8.3 | static word 0x98C00000 | `toc.data_u32(0x100d3e20,1)` | PASS |
| ai-scripts §9.1 | 8 direct bl, names | grep `$S/all.dis` + `tb.py --at` each | PASS |
| ai-scripts §9.2 | list bounds (0,0,0x20,1) = 32 slots | ctor `local_30=_DAT_100d85e0; local_2c=0x200001` | PASS |
| ai-scripts §9.3 | debug stop only for `0xaf < s < 0xcf` | PerformAI body | PASS |
| ui-play §0 | 105 rows / 27,040 B, all addresses in file | r1 grep + per-address grep | PASS |
| ui-play §2.3 | slot classes; class 5 needs both hands empty | CanDrop m:6722–7045 | PASS |
| ui-play §2.3 | ring cap `< 3` else needs-both-hands string | same | PASS |
| ui-play §2.2 | class 5 → slot 7 = −prop | `RecalcWieldList` (`+0x3a = -uVar5`) | PASS |
| ui-play §2.5 | refcons (3,4,5,6,7,8,13,176) | `struct.unpack('>8h', toc.D[0x100d4784-DB…])` | PASS |
| ui-play §6.1 | popup v=1 edit; else `(char)v − 0x53` | m:7290–7310 | PASS |
| ui-play §2.6 | non-party: visible+adjacent 0x110, visible 0x42, else close | m:6506–6560 | PASS |
| ui-play §5.2 | throw = IsStraightAbs/Rel; `& 0x60200 == 0x200` refused | DropCommand, IsStraightRel bodies | PASS |
| ui-play §4.3 | TrackControl result untested | `ppcdis.py 10035350 +12` | PASS |
| ui-play §4.3 | F-key table ten −1 | `toc.D` at 0x100d4a7c | PASS |
| magic §11.3 | RenderMissiles at pass 5, loop < 6 | `ppcdis.py 100676ec 10067710`, `10068780 10068790` | PASS |
| magic §11.3 | vtable 0x100D5F64 + 0x10 → RenderMissiles | `toc.data_u32` + `tb.py --at` | PASS |
| combat §17 | equip / +0x1E / throw cross-refs | as ui-play rows | PASS |
| ui-toolkit §3.1 | Down/Right past end → bound, selection lost | `ppcdis.py 1006da58 1006dc20` (`lha r0,78/76`) | PASS |
| ui-toolkit §3.1 | RevealCell gets the old cell | `1006dbf4: lwz r4,84(r1)` | PASS |
| ui-toolkit §3.2 | title last char never matches | `ppcdis.py 10073180 10073290` (`cmpw r3,r0; blt` vs length byte) | PASS |
| ui-toolkit §1 | WIND/DLOG procIDs, refCons, DLOG 128 title | `rsrc.parse` decode | PASS |
| ui-toolkit §1 | CDEF/WDEF stubs `4ef900000000`, MDEF zeros, LDEF 128 B | same | PASS |
| ui-toolkit §3.1 | 0x73–0x79 → 0x110–0x114 | p:3150–3170 | PASS |
| dialogue-ui §8 | key table; digits ignored unless new < max | m: KeyRoutine__12THowManyMode | PASS |
| dialogue-ui §8 | Cancel → 0; slider mapping ±16 px | MouseRoutine body | PASS |
| dialogue-ui §9 | pick-button key hang | `ppcdis.py 1003fffc 100401d4` (10040184 → 10040108 loop) | PASS |
| dialogue-ui §9 | only `/x` literals are 100E/300F | `grep -h -o '"[^"]*/[^"]*"'` | PASS (m12) |
| dialogue-ui §0 | 71 E rows / 15,788 B | census classifier | PASS (m9) |
| scripted-windows §4.1 | shortcut parse; `Cancel/c/`, `Leave/l/` unparsed | `ppcdis.py 1008a380 1008a3f0`; script greps | PASS |
| scripted-windows §5.8 | auto-map compares old y with new x | `ppcdis.py 1008ca00 1008ca80` | PASS |
| scripted-windows §5.9 | sel 23 receivers (10) ; 3017 False | `grep -l 'sel23[/@]'`; 3017 listing | PASS |
| scripted-windows §7 | panpipes/lyre masks, tunes, signals 129/131 | 1099/109A listings; 0xF79C3, 0xFC6 | PASS |
| scripted-windows §7 | 1175 handlers → 132–134 | 1175 listing | PASS |
| scripted-windows §8 | sender sites per selector | li-r4 scan filtered | PASS |
| script-builtins §2.1 | name table = census §4 | diff | PASS |
| script-builtins §3 | D3/D4 differ in param_5 only | `find_func.py 'cbPlaySound' --file missing` | PASS (m2) |
| script-builtins §3 | mixer table 16×0x34, clamp 0x80, count loop | p: FUN_100b7a58 / 7d60 / 7f40 | PASS |
| script-builtins §3 | 3 D4 calls, 83 D3 | `grep -h -o 'positional_sound[0-9]*('` | PASS |
| script-builtins §3 | helpers unnamed | `tb.py --at 100b7f40` → empty | PASS |
| script-library §9.1 | 89 sites distribution | census python | PASS |
| script-library §9.1 | every site's last r4 writer is `li` | own walk-back (40 instr, skip branches/stores) | PASS (0 exceptions) |
| script-library §9.1 | DoInterp0 only from the 4 wrappers; no `b` tail calls | `grep 'bl 0x10082b34'` → 4; `\bb 0x…` → 0 | PASS |
| script-library §9.1 | sel 18/19/61/62 no script send | doc's grep → 0 | PASS |
| script-vm ⚑ | item 21 arithmetic (t+2 expr, t+1 stmt, reset at return) | `ppcdis.py 1007ec88 1007eea8`, `10082260 100822c8`, `10081790 100817c4` | PASS |
| quests-flags §5 | step 12 inverted | 1025 listing 0396–045E | PASS |
| quests-flags §5 | Charax 05DA/05E2, distiller 00A8–00CE (use_on) | 184F, 10EA listings; 10EA dict `sel10/use_on@00A5` | PASS |
| quests-flags §2.3 | N2 bits 6/7 | 0C80 listing 001D/00B1 | PASS |
| schedules §4 ⚑ | 0x80 case = old-not-visible → new-visible | RepositionChar disasm (r19/r23 provenance) | PASS |
| schedules §6.2 ⚑ | 25 send_signal sites; bell 12865/4675 | grep; 10C1 listing | PASS |
| open-items §2 | F008: byte 7 = 0 (all 128 slots; 50 non-empty), f32/f33 counts | `seg.toc()` decode | PASS |
| open-items §2.3 | GetMonstAttrs; HandleMove `&2`; CanMove `&4` + DoInterp(9) | find_func greps | PASS |
| open-items §3.1 | only 2 native 0x80 clears on props | own decompiled-dump grep `& 0x7f` (p:21929, p:27901; others non-kind) | PASS |
| open-items §4 | kind 0x11 census | own decoder (m7) | PASS |
| open-items §5 | F005 bytes; no `,-4091`/`,-4089` | `seg.toc()`; grep `$S/all.dis` | PASS |
| open-items §5 | ColorCycle has no `bl` caller | `grep 'bl 0x10008694'` → 100432c4 | FAIL (m1) |
| open-items §6 | PORT 0/1 → 4096 B (2 / 204 values) | `lz.unlz` over `rsrc.parse` | PASS |
| open-items §7 | hintbook lines 563 / 1611 / 1959 | `pdftotext -layout` | PASS |

## 3. NOT RESOLVED items

| item | verdict | basis |
|---|---|---|
| 5 kind 0x11 | **accept close** (HIGH no reader; MED "leftover") | census reproduced; compare scan as stated |
| 6 F005/F007 | **accept close as no reader**; fix m1 sentence | literal-id scan 0; residual risk: a computed id (base + index) would escape a literal scan — none seen |
| 10 PORT | **accept close** | LZ decode reproduced |
| 14 indirect callers | **accept close** (HIGH) | TVector + absolute scan; 8 `bl` |
| 16 wall clock | **accept close** for the wall-clock half (m4 wording); **layer order still open**, narrowed by magic §11.3 | scheduler disasm; Render has no waits |
| 19 D4 flag | **accept close** (HIGH loop + name; MED end-of-sample) | PlaySound + mixer bodies |
| 21 0x9C FFFF | **accept close** (HIGH) | three disasm windows |
| 22 crystal quality | **accept close** (HIGH); wave 1 was inverted — confirmed; fix M2 | 1025, 1802, 184F, 10EA listings; hintbook agrees |
| 23 signals | **accept close** (both sides consistent; m11 wording) | listings + native senders |
| 24 F008 byte 7 / flags | **accept close** | data census + readers |
| 25 eggs / activity | **accept close**; rules.md fix owed (M1) | 0x80-clear scans; RepositionChar disasm |
| N2 | **accept narrowed** (HIGH bytes / MED intent) | 0C80 listing |
| N3 | **accept lift to HIGH** | independent r4 walk-back: 89/89 `li` |
