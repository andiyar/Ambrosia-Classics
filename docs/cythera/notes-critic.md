# notes — wave-1 synthesis & completeness critic (2026-10-03, Opus; read-only pass over f8870fc)

Method: read all eight wave-1 files + notes; opened every listing/dump line cited below (`ghidra/cythera-scripts/`,
`Cythera_pef.decompiled.c` via `find_func.py`/grep). **HIGH sampled 47, failed 6** (M1, M3, M4, M5, m6, m7) + 5 more
rest only on unbanked scratch tooling (B1, M7). Cross-references checked: 22 (listed in §2 findings). Counts:
**1 Blocker / 7 Major / 23 Minor.** No file > 650 lines (max dialogue.md 621).

## 1. Coverage vs mission
| asked | status | where |
|---|---|---|
| to-hit formula | banked HIGH | combat §6 (margin = (stat+rnd30) − (Reflex+rnd30) + off − def) |
| damage formula | banked HIGH | combat §5, §8 (`rnd(0,max)+1+quality`, verb ladder) |
| armour | banked HIGH | combat §9 (R0E81, 0x3040 resist bits) |
| death | partial (MED) | combat §12 — monster `Die` 0x100469C0 read from raw disasm only |
| XP + level thresholds | banked HIGH | combat §13 (min(dmg, gap+1); exp > 100·2^(L−1); +6 training) |
| spell costs + effects | banked HIGH | magic §2.2, §3 (49 spells), §4 ability-id table |
| alchemy recipes | banked HIGH | magic §7 (8 ingredient → potion frames, distiller cost 10 magic) |
| keyword matching (INDEX 13) | banked HIGH | dialogue §4 (prefix strncmp, first match wins), §6 (0x8F) |
| price arithmetic + table | banked HIGH | trade §3–§5, §7 (23 calls), §8 services |
| schedule work-type table | banked, **evidence unbanked** | schedules §2.1 (DoMove via scratch Ghidra — B1) |
| page-0x09 cond/action table | banked HIGH | schedules §1 |
| MoveAll pacing (INDEX 16) | banked HIGH; frame wait open | schedules §4, open-items §16 |
| flag catalogue + quest chain | banked HIGH/MED | quests §3, §5, §7 |
| INDEX 1, 4, 7, 8, 9, 10, 12, 18, 19 | resolved | open-items §1/§4/§7/§8/§9/§10/§12/§18/§19 (+combat §4, schedules §6.4, dialogue §7.1) |
| INDEX 5, 6 | partial | kind 0x11; 0xF005/0xF007 content (open-items §5/§6) |
| INDEX 13, 15 | resolved | dialogue; combat + magic + trade (over-encumbrance effect: none found, MED) |
| INDEX 14 | partial | +0x1E map + PerformAI callers (schedules §2.3/§9, scratch); CompileAIFile caller open |
| INDEX 16 | partial | pacing + sky resolved; Render layer order, DrawRoutine per-frame wait open |
| INDEX 2 (residue) | further resolved | 0x0A = potions, 0x0C40–55 = activity handlers, dead set (library §3/§5/§11); 0x03/0x05 words partly (quests §4.4) |

## 2. Findings (file · place · severity · defect → edit)
**B1** schedules-npcs.md §2.1, §2.2, §3.2, §4.2 vtable, §9 · **Blocker** · the work-type table, queue-code table, pre-emption and
PerformAI call sites are HIGH but quote a DoMove (0x1004B8E8) decompile from a scratch Ghidra postScript on `/private/tmp`;
nothing in the repo reproduces it (dump gap 0x1004b824–0x1004d704 confirmed). → bank the postScript (or a `tools/ppcdis.py`
listing recipe) + re-dump with `tools/tb.py` names, cite the command; until then label these rows MED.
**M1** trade-economy.md §11 (F008 census) + §13.8 · Major · "byte 6 of the character's record … census (first 128 characters)
… chars 0, 2, 3, 4 … merchants who do not bark" indexes 0xF008 by character id; `Ctor__Fsss` maps a character via
`ObjToMonst(CharEntry+0x14 & 0x3ff)` (dump line `_ObjToMonst__Fs(*(ushort *)(PTR_DAT_100cdbf0 + sVar6 * 0x20 + 0x14) & 0x3ff)`);
the 128 slots are species records (combat §4, open-items §6). → redo census by home type → record; delete the merchant claim.
**M2** quests-flags.md §0, §2.3, §4.1 (253–255 row), §10.1 · Major · activities 164–167 called "not decompiled"/"clear that bit";
schedules §3.2 reads 0xA4 wait-flag(+clear), 0xA5 set/clear flag, 0xA6 **wait until** char bit = value, 0xA7 set/clear bit.
→ rewrite §2.3 (166 with False = wait until bit clear), cite schedules §3.2, close open item 1 (after B1).
**M3** script-library.md §8 row 0F15 · Major (HIGH-row content wrong) · "callers pass (256, n, 1–8 ticks, 0)"; all 8 sites are
`R0F15(1, k, d, 0)` with `42 00 01` = 1, k 0–8 = vision type, d ∈ {5,2,1} (e.g. `1401 @00AF R0F15(1, 4, 2, 0)`).
→ fix to (1, type 0–8, byte6 1–5, 0); drop "LOW loc 256"; matches quests §6 and schedules §7.1.
**M4** open-items-2026-10-03.md §16 · Major · "Afraid/Paralysed/Confused/Charmed (status 0x20/0x40/0x2000/0x4000)": DoTick tests
0x4000 = Asleep (ability 22; magic §4.1, schedules §2.2); Charmed is 0x200 (data-format §6.1). → "Asleep".
**M5** open-items §7 row +0x17 · Major · calls 0EA5 "Sell routine", 0EA9 "buy routine" (inverse of trade/library) and says
"Every caller is `setfield …` (22 merchants)": 23 calls/22 segs, and 1869 @0215, 186A @0447, 1823 @0474 are `call …(…, 10, …)`.
→ align names with trade §3/§5 (R0EA5 = player buys), state the three literal-10 callers.
**M6** schedules-npcs.md §6.4 last line · Major · "Replica: omit or keep as a hidden debug toggle" — design advice, and "omit"
contradicts the 100 % replication standing ruling. → delete; record in DECISIONS only if Ben rules.
**M7** dialogue.md §0/§2.3–§3.3/§6 (raw `mygets`, `mygetch`, `ForceOut`, `myprintstr`, ConvResponse/More/Pick modes);
open-items §0, §8 (TStream), §18; combat §12.1 vtable; schedules §4.3, §6.4 · Major · HIGH on a "~60-line scratch PPC
decoder (not committed)" / r2 scans. `tools/ppcdis.py` and `tools/tb.py` are now appearing untracked. → once committed, add
the exact `ppcdis.py <start> <end>` / `tb.py` command beside each quote; any quote not reproducible by them → MED.
**m1** dialogue §0, §4.1 · `FUN_100b6dc8` listed as undecompiled; it is in the dump (`// ==== FUN_100b6dc8 @ 100b6dc8`, strncmp loop)
→ cite the decompile. **m2** schedules §6.2 row 256 · "MED: puVar3 not identified": TakeCommand has `puVar3 = PTR_DAT_100cdbb0`
(Nil), False = `PTR_DAT_100cde70` → HIGH, same wording as library §9 300F. **m3** quests §4.3, §10.3 "what sends 256 not
traced" → TakeCommand (trade §11). **m4** combat §11, §16.2 "who answers 321 not traced" → 3015 → R0D06/R0D07 + guards'
shared 0D07 (schedules §6.3). **m5** open-items §6 "bytes 3/4/7, u16@8/A, s16@E STILL OPEN" → combat §4 resolved all but byte 7.
**m6** open-items §7 +0x1D row "0E82/0E84 (health max)" — 0E84 is the attack/defence bonus (combat §6.3). **m7** trade §0/§3
"22 call sites" → 23 in 22 segments (grep `R0EA5(`). **m8** trade §8 drinks/§13.8 "ability 21 (drunk, LOW)", "activity 6 =
attack MED" → Confused HIGH (magic §4.1), Beserk (schedules §2.1). **m9** trade §11 R0D07 omits `0D07 @0003 jf (A31 == 256)` →
`@000E call R0D06`. **m10** library §7b preamble + §12.6 skill meanings "MED from use sites" → name methods `1AC0 @0005` … are
HIGH (combat §3, magic §6). **m11** library 0E8D "remains (LOW)" → type 77 = "blood" (`104D` header tile-name). **m12** quests §8
"spell type 246 … 1AF6@005D" → 0x1AF6 is the "Wait" command (`1af6 @0005 return "Wait"`). **m13** quests §4.1, §6 "class 0x28 #2
(0x1502)" → zone id 0x102, class 0x20 (open-items §12). **m14** G11/+6 training labelled HIGH (combat §13.2), HIGH/MED (magic
§6), MED (library 0E86, §12.4) → one label, all citing DoExpr 0x4B. **m15** open-items lacks §0 scope/not-read and a final
open-items section (Summary only) → add both. **m16** register: dialogue §5 l.263 "Consequence for a replica", §9.1 l.378 "a
replica must guard it", trade §6 l.285 "a replica must not copy", quests §2.4 l.122 "a replica must evaluate" → recast as
code facts. **m17** quests §7.4 transcribes ~38 to-do titles verbatim → ids + own-words labels, ≤1 quote. **m18** schedules §1
quote "0C55 @0003 … ; return 0" fuses lines 0003 and 0009 → cite both. **m19** trade §10, §13.10 durability open → combat:
no combat routine writes `.f06` (0E87 @0075 only reads) — state it in combat §7.3 and close. **m20** data-format §1.5 row 0x0101
still "encrypted? NOT RESOLVED" though INDEX 3/script-vm §8 settled it. **m21** `REPORT-implementer.md` (pre-wave) carries
the forbidden prefix → rename `notes-implementer.md`, fix INDEX/FIXPASS refs if any. **m22** library §12.1, quests §0 still
call 0x1004b824–0x1004d704 undumped → point at schedules §0 (DoMove 0x1004B8E8, after B1). **m23** `DAT_100d73f2`: "difficulty"
MED (combat), LOW (schedules §8.1), HIGH "never written" (open-items §8) → writers HIGH (restore only), name MED everywhere.

## 3. Synthesis plan (fix pass)
**INDEX.md Files table** — add rows after `engine-classes.md` (sections · labels HIGH MED LOW NOT RESOLVED unless noted):
- `combat.md` — 0 scope · 1 verdict + call graph · 2 native plumbing, `random` · 3 item properties/skills · 4 0xF008 creature
  table (class 0x48), spawn scaling · 5 attack choice 0x3042 · 6 to-hit · 7 parry/quality · 8 damage · 9 absorption/armour ·
  10 apply/status · 11 provocation · 12 death · 13 XP/levels · 14 encumbrance · 15 worked example · 16 open
- `magic.md` — 0 · 1 where magic lives · 2 casting (cost, failure, targeting) · 3 spell list + runes + damage path · 4 TSpellFX,
  ability-id table · 5 learning, magic points · 6 skills, training · 7 alchemy/potions · 8 magic items · 9 worked example · 10 open
- `dialogue.md` — 0 · 1 start · 2 printing/panes · 3 `input` 0x8E · 4 keyword matching 0x90 · 5 chips · 6 prompts 0x8F ·
  7 numbers/party/menus · 8 skeleton + topic libraries · 9 knowledge gates · 10 portraits · 11 ending · 12 barks · 13 UI modes ·
  14 catalogue of 127 talk methods · 15 open
- `trade-economy.md` — 0 · 1 obol + money library · 2 weight/capacity · 3 buy R0EA5 · 4 haggling · 5 sell R0EA9 · 6 dead shop API ·
  7 price tables · 8 services · 9 training costs · 10 quality · 11 theft · 12 worked example · 13 open
- `schedules-npcs.md` — 0 · 1 page-0x09 AI routines · 2 activity byte (work types), behaviour byte · 3 activity queue ·
  4 pacing · 5 party follow · 6 signals/hostility, all-ally cheat · 7 map/room hooks · 8 spawning, monster classes ·
  9 PerformAI/CompileAIFile · 10 open
- `quests-flags.md` — 0 · 1 persistent stores · 2 bit helpers · 3 per-character flag catalogue · 4 flags/vars/globals/data words ·
  5 main chain + end_game · 6 visions/teleports/time · 7 side chains, to-do slots · 8 party gating · 9 journal · 10 open
- `script-library.md` — 0 · 1 page entry · 2–9 per-page routine tables (0x08, 0x0A–0x0F, 0x30) · 10 heavy routines · 11 dead ·
  12 open
- `open-items-2026-10-03.md` — per-INDEX-item resolutions 1, 4–10, 12, 16, 18, 19 + summary (work order; folded by fix pass)
- `notes-*.md` — one per reader (+ `notes-critic.md`), counts and top findings (no labels)
- Provenance "tools" row: add `scriptdis.py`, and `ppcdis.py` + `tb.py` once committed (with their recipe lines).
**NOT RESOLVED list** — append `⚑ corrected (wave 1 2026-10-03)` with pointer:
1 struck → open-items §1 · 2 annotate (0x0A potions, 0x0C40–55 activity handlers, dead set → library §3/§5/§11; 0x0301/0500/0501
words → quests §4.4); open: rest of 0x03/0x05 words · 3 unchanged · 4 struck → open-items §4 · 5 annotate; open: kind 0x11 ·
6 annotate (F008 combat §4, F00D/F00F/F011/F012/F014/F015/F00A open-items §6); open: F005/F007 · 7 struck → open-items §7,
combat §4.1/§6.3, trade §3.1, schedules §4.2 · 8 struck → open-items §8, quests §1 · 9 struck; open sub-point: QTMA events ·
10 struck; open sub-point: PORT content · 12 struck → open-items §12, combat §4 · 13 struck → dialogue §3–§6 · 14 annotate
(schedules §2.3, §9); open: CompileAIFile caller · 15 struck → combat, magic, trade; open sub-point: over-encumbrance effect
(none found, MED) · 16 annotate (pacing/sky open-items §16, schedules §4); open: Render layer order, per-frame wait ·
18 struck → open-items §18, schedules §6.4 · 19 struck → open-items §19, dialogue §7.1/§7.2; F8 out of scope.
New consolidated items: 20 DoMove/Die/LeaveLevel absent from the dump (B1, combat §16.1) · 21 0x9C FFFF stack-slot path now
live in shipped data (library §10.1/§10.2) · 22 damned-ending crystal quality source (quests §5) · 23 signals 1/34/35/100+/129–135
receivers (schedules §6.2) · 24 F008 byte 7 + unread flag bits (combat §16.4) · 25 egg re-arming, post-walk activity restore.
**Review ledger** — add: "**2026-10-03 — wave 1 rules banks (f8870fc), critic: 1 Blocker / 7 Major / 23 Minor** (full text
`notes-critic.md`); each fix marked `⚑ corrected (wave 1 2026-10-03)`."
**rules.md** — one line under each heading: §1 → "Full combat arithmetic: `combat.md` (supersedes the pointer row)." · §2 →
"XP/levels `combat.md` §13; party follow/formation `schedules-npcs.md` §5; turn pacing `schedules-npcs.md` §4." · §3 → "Work
types, activity queue, signals: `schedules-npcs.md` §2–§7; story-state conditions `quests-flags.md` §2.4." · §4 → "Ability ids
and TSpellFX: `magic.md` §4." · §5 → "Full dialogue system: `dialogue.md`." · §6 → "Magic/alchemy/skills `magic.md`; trade
`trade-economy.md`; routine reference `script-library.md`."
**data-format.md** — §5 row 0xF008: "128 × 16-byte creature-species records keyed by u16 +0xC (object type), 50 used; field map
combat.md §4; tail list after +0x800 empty" ⚑ (replaces "header … 0 records"); rows 0xF00D, 0xF00F, 0xF011/0xF012,
0xF00A/0xF014/0xF015 → open-items §6; §6.1 rows: +0x06 add 0x4000 Asleep; +0x12 busy ticks; +0x17 merchant markup (trade §3.1);
+0x18 sub-move state (open-items §7); +0x1D class: bits 0–1 / 2–3 growth codes (combat §6.3, open-items §7); +0x1E behaviour
values (schedules §2.3, MED → HIGH after B1); +0x1F spawn scale % (combat §4.1); §1 header +0x20/+0x40/+0x42/+0x48; §1.5
rows 0x0101 (m20), 0x9000/0x9100 formats; §3.1 +0x04/+0x14–0x1F unused + `C*0x40` defect; §4 +0xA/+0xE/kind 0x80/'B'
frames; §7 the four `hhhh` + chunk encodings. **script-vm.md** §2.1: row 0x28 → "no producer; 0x1500–0x1502 are class-0x20
zone ids 0x100–0x102" HIGH; row 0x48 → "monster-species records of 0xF008" HIGH; §8 0x9C FFFF note: "live — 0816 (113/114
entries), 0EA5 (every entry)". **script-builtins.md** §4: glue callees, D0, E2, FC (open-items §19); B4 args, BB (dialogue §7).
**docs/STATE.md** (one line under Open item 2): "Cythera wave 1 rules banks landed (f8870fc: combat, magic, dialogue, trade,
schedules, quests, script-library, open-items); critic `docs/cythera/notes-critic.md` 1 Blocker/7 Major/23 Minor — fix pass +
INDEX synthesis next."
