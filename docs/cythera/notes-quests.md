# notes — quests-flags reader (2026-10-03)

**Read**: all 958 `scriptdis` listings (scripted extraction of every bit-helper, flag, variable,
to-do, end_game, teleport, pass_time, party, 0x85/0x87/0x49 site), then the sites by hand;
native `GetField/SetField`, `Get/SetGlobal`, `Builtin_AE/DC–DF/F1`, `TToDo`, `TJournal`,
`SaveToFile`, `TeleportTo`, `IsEqual`, the 0x85 save path; data 0xF009, 0xF00B, 0xF00C, 0x8100+L.
No hintbook in the install folder.

**Counts**: setbit 246 / clrbit 17 / tstbit 297 / inparty 64; set_flag 11, test_flag 28,
wait_for_flag 6; set_variable 53, get_variable 168; add_to_do 41, done_to_do 32; end_game 4.

**Top findings**: the "flag array" is CharEntry byte +8 (8 bits per character; bit 6 party,
bit 7 name known), saved in 0xF009 and read by schedules; karma = G0C and G0E are the first two
`hhhh` save values; var 0 picks the ending; seg0500:0010 = female hero, seg0301:0016 = rented
inn bed; two `who_in_party_has(…) == -1` checks can never match Nil (dead branches); room 301
tests Timon bit 3 but sets bit 2; to-do slot 17 is never completable; the journal has no
script path.

**Open**: activity 164–167 semantics, the damned-ending crystal quality source, signal 256,
never-set bits (Hero 0, Magpie 1, Glaucus 7, flag 2).
