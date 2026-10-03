# notes — trade and economy reader (2026-10-03)

Read: script-census, script-vm, script-builtins, rules; ~45 listings in full (page 0x0D money
library, 0E91–0EB1 shop/haggle/sleep/training, 0812 dice, 300F/3015/3043 theft, 1082 obol, 100E
bed) plus the trade sections of 23 merchants; 20 engine bodies (encumbrance, counts, GetField,
B4/B7/B8/C0/CA); 0xF009 +0x17, 0xF008 byte 6, 0x0201 names via seg.py. No hintbook PDF exists in
the data folder.

Output: `trade-economy.md`, 508 lines; HIGH 85 / MED 18 / LOW 2.

Top findings:
- Coin = type 130, weight 1 (0.1 displayed), value via selector 60; money library R0D01–R0D0A.
- One live buy routine R0EA5 (22 sites): price `((base*markup)+9)/10`, markup = CharEntry +0x17
  (resolves data-format's untraced byte), persisted per merchant; no weight check on purchase.
- Haggle formula banked; its "can't afford" lie penalty is dead (compares a widget to 0).
- Sell R0EA9: `((base*qty*10)+5)/markup`, split across party, overflow coins drop to the floor.
- Full price table (23 shops), inn/meal/drink costs, inn-token beds, dice game, weapon
  improvement `10 << quality` obsidian, theft via 0x300F + signals 256/320/321.
- Six page-0x0E shop routines are dead.

Open: PickItem/HowMany bodies, widget classes, activity 6 / ability 21 meanings, F008 byte 6
reconciliation, THeap double release in R0EA9.
