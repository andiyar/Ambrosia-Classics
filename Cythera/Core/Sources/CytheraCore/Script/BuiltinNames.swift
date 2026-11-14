import Foundation

/// The 95 native builtin names, opcodes 0xA0–0xFE, verbatim from `docs/cythera/tools/scriptdis.py` `BUILTINS`
/// (lines 39–135; script-builtins.md §2, snake_case of "name (ours)"). These are the listing's tokens and the
/// parity form's vocabulary: a builtin instruction's mnemonic is `builtin`, its name goes in the operand text.
/// 0xFF has no name: its table entry is a null TVector (script-vm.md §6, §8).
public enum BuiltinNames {
    /// Index = opcode − 0xA0.
    public static let names: [String] = [
        "iterate_range",               // A0
        "iterate_list",                // A1
        "end_game",                    // A2
        "add_leader_busy",             // A3
        "show_portrait",               // A4
        "set_tile_animation",          // A5
        "show_tile_animate",           // A6
        "delete_prop",                 // A7
        "give_item",                   // A8
        "map_cell",                    // A9
        "stub_aa",                     // AA
        "transfer_item",               // AB
        "random",                      // AC
        "create_prop",                 // AD
        "who_in_party_has",            // AE
        "find_item",                   // AF
        "count_items",                 // B0
        "remove_items",                // B1
        "party_member",                // B2
        "who_will",                    // B3
        "how_many",                    // B4
        "ask_digit",                   // B5
        "stub_b6",                     // B6
        "free_capacity",               // B7
        "weight_if_added",             // B8
        "join_party",                  // B9
        "leave_party",                 // BA
        "who_will_prompt",             // BB
        "leader_can_see",              // BC
        "pass_time",                   // BD
        "refresh_light",               // BE
        "teleport",                    // BF
        "pick_item",                   // C0
        "add_ability",                 // C1
        "remove_ability",              // C2
        "temp_ability",                // C3
        "has_ability",                 // C4
        "send_signal",                 // C5
        "short_name",                  // C6
        "iterate_all_props",           // C7
        "iterate_children",            // C8
        "iterate_descendants",         // C9
        "iterate_party",               // CA
        "iterate_props_at",            // CB
        "iterate_equipped",            // CC
        "iterate_props_of_type",       // CD
        "iterate_enemies_of",          // CE
        "iterate_last_burst_victims",  // CF
        "iterate_same_group",          // D0
        "iterate_props_near",          // D1
        "play_note",                   // D2
        "positional_sound",            // D3
        "positional_sound2",           // D4
        "play_music",                  // D5
        "play_music2",                 // D6
        "ambient_sound",               // D7
        "set_zone_light_minimum",      // D8
        "set_outdoor_sky",             // D9
        "set_map_title",               // DA
        "scripted_window_shown",       // DB
        "get_variable",                // DC
        "set_variable",                // DD
        "test_flag",                   // DE
        "set_flag",                    // DF
        "reschedule",                  // E0
        "show_magic",                  // E1
        "missile_burst",               // E2
        "show_hit",                    // E3
        "show_attack",                 // E4
        "next_sibling",                // E5
        "set_arrival_byte",            // E6
        "screen_effect",               // E7
        "begin_talking",               // E8
        "end_talking",                 // E9
        "conversation_cue_2",          // EA
        "conversation_cue_1",          // EB
        "open_curtain",                // EC
        "close_curtain",               // ED
        "curtain_picture",             // EE
        "set_waypoint",                // EF
        "queue_activity",              // F0
        "wait_for_flag",               // F1
        "add_to_do",                   // F2
        "done_to_do",                  // F3
        "add_answer",                  // F4
        "find_skill",                  // F5
        "view_at",                     // F6
        "straight_line",               // F7
        "cd_audio",                    // F8
        "next_serial",                 // F9
        "find_unique_prop",            // FA
        "stub_fb",                     // FB
        "set_viewer_flag_d",           // FC
        "set_erase_colour",            // FD
        "stub_fe",                     // FE
    ]

    /// The name of builtin `op`, or nil outside 0xA0–0xFE.
    public static func name(_ op: UInt8) -> String? {
        guard op >= 0xA0, op <= 0xFE else { return nil }
        return names[Int(op) - 0xA0]
    }
}
