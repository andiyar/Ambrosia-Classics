#!/usr/bin/env python3
"""scriptdis.py — disassembler for Cythera 1.0.4 script bytecode (TInterp, "DSInterp2").

Reads `Cythera Data` (TSegFile), decrypts every segment of the script band (pages 0x01..0x3F)
with the id-keyed XOR LCG (data-format.md 1.3, via seg.py), classifies each segment by
*measuring* its structure, and disassembles code with the banked VM (script-vm.md incl. the
2026-10-03 review corrections: 0x53 = !=, 0x54 == ; slots 0x00-0x2F locals, 0x30-0x3F args;
0x9C seg16 <int-expr> <args>) cross-checked against the Ghidra decompile of
DoExpr__7TInterpFRPUc @ 1007ddfc and DoInterpAt__7TInterpFsP5VAddr @ 10080c98.

Script segments are NOT LZ-compressed (LZ is only used for pixel data, data-format.md 2); the
interpreter reads them through TCachedSegFiles::GetEncryptedSegment @ 1007d148 = LoadSegment +
Decrypt, nothing else.

Output: one listing per segment (`<out>/<segid>.txt`), and with --census a markdown census.
Stdlib only.

Usage:
  scriptdis.py [--data PATH] [--out DIR] [--seg HEX ...] [--census [FILE]] [--quiet]
"""
import argparse, collections, os, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import seg as segmod  # noqa: E402  (toc() and dec())

DEFAULT_DATA = segmod.DATA

# ------------------------------------------------------------------------------------------
# Banked tables
# ------------------------------------------------------------------------------------------
# Builtins 0xA0..0xFF: names/arg lists from script-builtins.md section 2 (snake_case of "name (ours)").
BUILTINS = {
    0xA0: ('iterate_range', '(slot, mode, start, end)'),
    0xA1: ('iterate_list', '(slot, mode, list)'),
    0xA2: ('end_game', '(string)'),
    0xA3: ('add_leader_busy', '(n)'),
    0xA4: ('show_portrait', '(a, b)'),
    0xA5: ('set_tile_animation', '(tile, first, frames)'),
    0xA6: ('show_tile_animate', '(n)'),
    0xA7: ('delete_prop', '(prop)'),
    0xA8: ('give_item', '(char, item, quality, count)'),
    0xA9: ('map_cell', '(x, y)'),
    0xAA: ('stub_aa', '()'),
    0xAB: ('transfer_item', '(item, quality, fromChar, toChar)'),
    0xAC: ('random', '(lo, hi)'),
    0xAD: ('create_prop', '(kind, x, y, frame, type, byte6, count)'),
    0xAE: ('who_in_party_has', '(item, quality or 0)'),
    0xAF: ('find_item', '(char, item, quality)'),
    0xB0: ('count_items', '(char, item)'),
    0xB1: ('remove_items', '(char, item, quality, count)'),
    0xB2: ('party_member', '(n, mode)'),
    0xB3: ('who_will', '(includeDead)'),
    0xB4: ('how_many', '(prompt or Nil, a, b)'),
    0xB5: ('ask_digit', '()'),
    0xB6: ('stub_b6', '()'),
    0xB7: ('free_capacity', '(char)'),
    0xB8: ('weight_if_added', '(x, count)'),
    0xB9: ('join_party', '(char)'),
    0xBA: ('leave_party', '(char)'),
    0xBB: ('who_will_prompt', '(string)'),
    0xBC: ('leader_can_see', '(obj or int)'),
    0xBD: ('pass_time', '(n)'),
    0xBE: ('refresh_light', '()'),
    0xBF: ('teleport', '(a, b, c)'),
    0xC0: ('pick_item', '(prompt or Nil, title or Nil, items, strings)'),
    0xC1: ('add_ability', '(who, ability)'),
    0xC2: ('remove_ability', '(who, ability)'),
    0xC3: ('temp_ability', '(who, ability, duration)'),
    0xC4: ('has_ability', '(who, ability)'),
    0xC5: ('send_signal', '(n)'),
    0xC6: ('short_name', '(obj)'),
    0xC7: ('iterate_all_props', '(slot, mode)'),
    0xC8: ('iterate_children', '(slot, mode, parent)'),
    0xC9: ('iterate_descendants', '(slot, mode, parent)'),
    0xCA: ('iterate_party', '(slot, mode)'),
    0xCB: ('iterate_props_at', '(slot, mode, x, y)'),
    0xCC: ('iterate_equipped', '(slot, mode, char)'),
    0xCD: ('iterate_props_of_type', '(slot, mode, type)'),
    0xCE: ('iterate_enemies_of', '(slot, mode, char)'),
    0xCF: ('iterate_last_burst_victims', '(slot, mode)'),
    0xD0: ('iterate_same_group', '(slot, mode, who)'),
    0xD1: ('iterate_props_near', '(slot, mode, x, y, r)'),
    0xD2: ('play_note', '(a, b, c)'),
    0xD3: ('positional_sound', '(id, x, y)'),
    0xD4: ('positional_sound2', '(id, x, y)'),
    0xD5: ('play_music', '(n or Nil)'),
    0xD6: ('play_music2', '(n or Nil)'),
    0xD7: ('ambient_sound', '(id, x, y)'),
    0xD8: ('set_zone_light_minimum', '(n)'),
    0xD9: ('set_outdoor_sky', '(n)'),
    0xDA: ('set_map_title', '(string)'),
    0xDB: ('scripted_window_shown', '(obj)'),
    0xDC: ('get_variable', '(i)'),
    0xDD: ('set_variable', '(i, v)'),
    0xDE: ('test_flag', '(n)'),
    0xDF: ('set_flag', '(n, v)'),
    0xE0: ('reschedule', '()'),
    0xE1: ('show_magic', '(obj, n)'),
    0xE2: ('missile_burst', '(x0, y0, x1, y1, tile, flags, radius, a7)'),
    0xE3: ('show_hit', '(a, b, c)'),
    0xE4: ('show_attack', '(a, b, c, d, list or int)'),
    0xE5: ('next_sibling', '(prop)'),
    0xE6: ('set_arrival_byte', '(n)'),
    0xE7: ('screen_effect', '(n)'),
    0xE8: ('begin_talking', '()'),
    0xE9: ('end_talking', '()'),
    0xEA: ('conversation_cue_2', '()'),
    0xEB: ('conversation_cue_1', '()'),
    0xEC: ('open_curtain', '()'),
    0xED: ('close_curtain', '()'),
    0xEE: ('curtain_picture', '(PICT id, text or Nil)'),
    0xEF: ('set_waypoint', '(char, x, y)'),
    0xF0: ('queue_activity', '(char, act, x, y, value)'),
    0xF1: ('wait_for_flag', '(n)'),
    0xF2: ('add_to_do', '(n, v)'),
    0xF3: ('done_to_do', '(n)'),
    0xF4: ('add_answer', '(string)'),
    0xF5: ('find_skill', '(char, skill)'),
    0xF6: ('view_at', '(x, y)'),
    0xF7: ('straight_line', '(x0, y0, x1, y1)'),
    0xF8: ('cd_audio', '(op, v)'),
    0xF9: ('next_serial', '()'),
    0xFA: ('find_unique_prop', '(n)'),
    0xFB: ('stub_fb', '()'),
    0xFC: ('set_viewer_flag_d', '(bool)'),
    0xFD: ('set_erase_colour', '(n)'),
    0xFE: ('stub_fe', '()'),
    # 0xFF: TVector table entry is null (script-builtins.md) -> counted as an unknown/invalid op.
}

# Selectors sent by native code (script-vm.md 2.3; names inferred from the sender [MED]) and the
# type properties FillIntfCache reads (data-format.md 4.4).
SELECTORS = {
    0: 'init', 2: 'name', 3: 'len', 4: 'index', 7: 'first_visit', 8: 'search', 9: 'use',
    10: 'use_on', 12: 'talk', 13: 'wield', 14: 'take_drop_14', 15: 'take_drop_15',
    16: 'take_drop_16', 17: 'take_drop_17', 20: 'enter', 21: 'signal', 24: 'take_drop_24',
    25: 'take_drop_25', 27: 'wield_slide', 28: 'attack', 29: 'death', 31: 'moved', 32: 'spawned',
    0x24: 'p_weight', 0x27: 'p_typeflags27', 0x28: 'p_typeflags28', 0x22: 'p22', 0x23: 'p23',
    0x25: 'p25', 0x26: 'p26', 0x37: 'p37', 0x3A: 'p3A', 0x3B: 'p3B',
}

# Object classes (script-vm.md 2.1).  `ObjIDToSegmentID(class,id) = 0x1000 + class*0x20 + id`
# (classes 0 and 0x50: id is a prop index replaced by the prop's type at run time).
CLASSES = {0x00: 'prop', 0x20: 'zone', 0x28: 'cls28', 0x40: 'char', 0x48: 'cls48',
           0x50: 'spell', 0x58: 'room', 0x78: 'gremlin'}
SYS_CLASSES = {4: 'window', 5: 'widget'}
# page -> class per script-vm.md 2.1 table (0x1C = rooms with id >= 0x100).
PAGE_CLASS = {0x10: 0x00, 0x11: 0x00, 0x12: 0x00, 0x13: 0x00, 0x14: 0x20, 0x15: 0x28, 0x18: 0x40,
              0x19: 0x48, 0x1A: 0x50, 0x1B: 0x58, 0x1C: 0x58, 0x1F: 0x78}

# GetGlobal__Fs @ 1009376c / SetGlobal__Fs5VAddr @ 10093a5c (read this session).
GLOBALS = {0: 'hour', 1: 'globstr1', 2: 'globstr2', 3: 'globstr3', 4: 'clock', 5: 'leader',
           6: 'party_size', 7: 'party_size7', 9: 'speaker', 10: 'globstr10', 0xC: 'g0C_0to100',
           0x11: 'g11_unhandled',
           0xD: 'g0D', 0xE: 'g0E', 0xF: 'day', 0x10: 'zone', 0x12: 'room', 0x13: 'g13_bool'}
GLOBSTR = {1: 'time_of_day', 2: 'player_name', 10: 'last_input'}

# GetField__Fsss @ 100921b4 / SetField__Fsss5VAddr @ 10092bd4 (read this session); names use the
# CharEntry / PropItem field names of data-format.md 4.2 and 6.1.
FIELDS_PROP = {0: 'kind', 1: 'x', 2: 'y', 3: 'frame', 4: 'type', 5: 'item', 6: 'quality',
               7: 'byte7', 8: 'u16_6', 9: 'count', 0xA: 'tile', 0xB: 'loc16', 0xC: 'tblC40',
               0xD: 'mirror', 0xE: 'unique', 0xF: 'u16_A', 0x10: 'byteE', 0x11: 'has_frame',
               0x12: 'frame_dict'}
FIELDS_CHAR = {0x13: 'flags', 0x14: 'status', 0x15: 'activity', 0x16: 'behaviour',
               0x17: 'body', 0x18: 'reflex', 0x19: 'mind', 0x1A: 'exp', 0x1B: 'level',
               0x1C: 'health', 0x1D: 'health_max', 0x1E: 'magic', 0x1F: 'magic_max',
               0x20: 'ce1D', 0x21: 'training', 0x22: 'target', 0x23: 'busy', 0x24: 'typeframe',
               0x25: 'home', 0x26: 'f26', 0x27: 'ce17', 0x28: 'food'}

BINOPS = {0x4A: '+', 0x4B: '-', 0x4C: '*', 0x4D: '/', 0x4E: '%', 0x4F: '<', 0x50: '<=',
          0x51: '>', 0x52: '>=', 0x53: '!=', 0x54: '==', 0x56: '&', 0x57: '|', 0x58: '^',
          0x5A: '<<', 0x5B: '>>', 0x5C: '&&', 0x5D: '||'}
UNOPS = {0x55: '-', 0x59: '~', 0x5E: '!'}

STMT_NAMES = {0x00: 'nop', 0x81: 'frame', 0x82: 'set', 0x83: 'store', 0x84: 'atput',
              0x85: 'gstore', 0x86: 'setfield', 0x87: 'setglobal', 0x88: 'goto',
              0x89: 'switch', 0x8A: 'print', 0x8B: 'return', 0x8C: 'jt', 0x8D: 'jf',
              0x8E: 'input', 0x8F: 'prompt', 0x90: 'match', 0x91: 'nop91', 0x92: 'raise',
              0x93: 'release', 0x9B: 'sysnew', 0x9C: 'callx', 0x9D: 'send', 0x9E: 'callsub',
              0x9F: 'call'}
INVALID_STMT = {0x80} | set(range(0x94, 0x9B)) | {0xFF}
INVALID_EXPR = set(range(0x65, 0x9B)) | {0xFF}


def u16(b, o):
    return (b[o] << 8) | b[o + 1]


def u32(b, o):
    return struct.unpack('>I', b[o:o + 4])[0]


def s28(v):
    v &= 0xFFFFFFF
    return v - 0x10000000 if v & 0x8000000 else v


def tag_of(v):
    return -1 if v & 0x80000000 else v >> 28


def cstr(b, o, stop_high=False):
    """C string at o: up to NUL (stop_high: also stop at a byte >= 0x80, like GetString)."""
    e = o
    while e < len(b) and b[e] != 0 and not (stop_high and b[e] >= 0x80):
        e += 1
    return b[o:e], e


def show_text(raw, limit=None):
    s = raw.decode('mac_roman', 'replace')
    s = s.replace('\\', '\\\\').replace('"', '\\"').replace('\r', '\\r').replace('\n', '\\n')
    if limit and len(s) > limit:
        s = s[:limit] + '…'
    return '"' + s + '"'


# ------------------------------------------------------------------------------------------
# Segment store
# ------------------------------------------------------------------------------------------
class Store:
    def __init__(self, path):
        self.path = path
        self.file, self.toc, self.pages = segmod.toc(path)
        self.raw = {}
        for sid, (o, l) in self.toc.items():
            self.raw[sid] = self.file[o:o + l]
        self.data = {}      # sid -> bytes as the engine sees them (decrypted)
        self.kind = {}      # sid -> classification
        self.plain = set()  # stored plaintext (decrypting would garble)
        self.notes = collections.defaultdict(list)
        self._classify()
        self._names()

    # --- structure probes (measured, not assumed) ---
    @staticmethod
    def probe_strtab(b):
        """0x90-0x9F array header whose entries' low 16 bits (all VAddrToPtr case 3 uses) point
        at NUL-terminated strings after the table; Nil (0x5000FFFF) entries tolerated."""
        if len(b) < 2 or not 0x90 <= b[0] <= 0x9F:
            return False
        n = u16(b, 0) & 0xFFF
        if n == 0 or 2 + 4 * n > len(b):
            return False
        good = 0
        for i in range(n):
            v = u32(b, 2 + 4 * i)
            if v == 0x5000FFFF:
                continue
            off = v & 0xFFFF
            if off < 2 + 4 * n or off >= len(b) or b[off] >= 0x80 or 0 not in b[off:]:
                return False
            good += 1
        return good > 0

    @staticmethod
    def probe_class(b):
        if len(b) < 4:
            return False
        off = u16(b, 0)
        if off + 2 > len(b) or not 0xA0 <= b[off] <= 0xAF:
            return False
        n = u16(b, off) & 0xFFF
        return off + 2 + 6 * n <= len(b)

    @staticmethod
    def probe_dict(b):
        if len(b) < 2 or not 0xA0 <= b[0] <= 0xAF:
            return False
        return 2 + 6 * (u16(b, 0) & 0xFFF) <= len(b)

    def _probe(self, sid, b):
        p = sid >> 8
        if 0x10 <= p <= 0x1F and self.probe_class(b):
            return 'class'
        if b[:1] == b'\x81':
            return 'routine'
        if self.probe_strtab(b):
            return 'strtab'
        if self.probe_dict(b):
            return 'dict'
        if len(b) >= 2 and 0x90 <= b[0] <= 0x9F and 2 + 4 * (u16(b, 0) & 0xFFF) <= len(b):
            return 'array'
        return None

    @staticmethod
    def self_pointers(sid, b):
        """Does a dictionary at the start (or at the class dict offset) hold code pointers into
        this very segment?  Used to accept a stored-plaintext segment."""
        offs = [0, u16(b, 0) if len(b) >= 2 else 0]
        for off in offs:
            if off + 2 > len(b) or not 0xA0 <= b[off] <= 0xAF:
                continue
            n = u16(b, off) & 0xFFF
            for i in range(n):
                if off + 6 + 6 * i > len(b):
                    break
                v = u32(b, off + 2 + 6 * i)
                if v & 0x80000000 and (v >> 16) & 0x7FFF == sid and (v & 0xFFFF) < len(b):
                    return True
        return False

    def _classify(self):
        for sid in sorted(self.raw):
            p = sid >> 8
            if not 0x01 <= p <= 0x3F:
                continue
            raw = self.raw[sid]
            if p == 0x04:
                # compiled combat-AI scripts: plain, own format (ai-scripts.md 3), not VM bytecode
                self.kind[sid] = 'ai'
                self.data[sid] = raw
                continue
            dec = segmod.dec(raw, sid)
            k = self._probe(sid, dec)
            if k is None:
                kr = self._probe(sid, raw)
                if kr in ('dict', 'class') and not self.self_pointers(sid, raw):
                    kr = None    # a random header byte, not a real structure
                if kr in ('strtab', 'dict', 'class'):
                    self.plain.add(sid)
                    self.kind[sid] = kr
                    self.data[sid] = raw
                    self.notes[sid].append(
                        'stored PLAINTEXT in the shipped file: the decrypted bytes match no '
                        'structure, the raw bytes do (%s). GetEncryptedSegment @ 1007d148 always '
                        'decrypts, so the interpreter would read garbage here.' % kr)
                    continue
                k = 'data'
            self.kind[sid] = k
            self.data[sid] = dec

    # --- name sources ---
    def strtab(self, sid):
        b = self.data.get(sid)
        if b is None or self.kind.get(sid) != 'strtab':
            return None
        n = u16(b, 0) & 0xFFF
        return [cstr(b, u32(b, 2 + 4 * i) & 0xFFFF)[0] for i in range(n)]

    def string_ref(self, sid, idx):
        """VAddrToPtr case 3: string #idx of the table at the start of segment sid, idx clamped
        to count-1 (review finding 11)."""
        b = self.data.get(sid)
        if b is None or len(b) < 2:
            return None, 'missing segment'
        n = u16(b, 0) & 0xFFF
        if n == 0 or 2 + 4 * n > len(b):
            return None, 'no table'
        clamped = idx >= n
        i = n - 1 if clamped else idx
        if u32(b, 2 + 4 * i) == 0x5000FFFF:
            return b'', 'entry %d is Nil (index base for str+int)' % i
        off = u32(b, 2 + 4 * i) & 0xFFFF
        if off >= len(b):
            return None, 'bad offset'
        s, _ = cstr(b, off)
        return s, ('clamped to %d' % i if clamped else '')

    def _names(self):
        self.char_names = {}
        t = self.strtab(0x0201)
        if t:
            self.char_names = {i: s for i, s in enumerate(t)}
        # tile names (0xF004) and base tile per type (0xF000): plain segments
        self.type_names = {}
        try:
            f000 = self.raw[0xF000]
            f004 = self.raw[0xF004]
            ranges = []
            o = 0
            while o + 2 <= len(f004):
                last = u16(f004, o)
                if last > 0x2000:
                    break
                s, e = cstr(f004, o + 2)
                ranges.append((last, s))
                o = e + 1
            for ty in range(0x400):
                tile = u16(f000, 2 * ty)
                for last, s in ranges:
                    if tile <= last:
                        self.type_names[ty] = s
                        break
        except KeyError:
            pass

    def seg_label(self, sid):
        """Human label for a segment id (class/selector/routine role per the bank)."""
        p = sid >> 8
        if 0x10 <= p <= 0x1F:
            c = PAGE_CLASS.get(p)
            if c is None:
                rel = sid - 0x1000
                cands = ['0x%02X/%s id %d' % (k, CLASSES[k], rel - 0x20 * k)
                         for k in sorted(CLASSES) if rel - 0x20 * k >= 0]
                return ('object class page 0x%02X: not assigned by the bank; formula '
                        '0x1000+class*0x20+id candidates: %s' % (p, '; '.join(cands[-3:])))
            i = sid - 0x1000 - 0x20 * c
            name = CLASSES.get(c, 'cls%02X' % c)
            extra = ''
            if c == 0x00 and i in self.type_names:
                extra = " tile-name %s (tool join F000/F004)" % show_text(self.type_names[i], 40)
            if c == 0x40 and i in self.char_names:
                extra = " name %s (string table 0201)" % show_text(self.char_names[i], 40)
            idname = 'type' if c in (0x00, 0x50) else 'id'
            return 'class 0x%02X (%s) %s %d%s' % (c, name, idname, i, extra)
        if p == 0x30:
            s = sid - 0x3000
            return 'routine: default handler for selector %d%s' % (
                s, ' (%s)' % SELECTORS[s] if s in SELECTORS else '')
        if p == 0x09:
            k = sid & 0xFF
            if k >= 0x80:
                return 'routine: combat-AI scenario action %d (ai-scripts.md 5)' % (k - 0x80)
            return 'routine: combat-AI scenario test %d (ai-scripts.md 5)' % k
        if p == 0x02:
            if sid == 0x0201:
                return 'string table (character names: GetCharacterName reads 0x30000201|id<<16)'
            return 'string table'
        if p == 0x04:
            return 'compiled combat AI (ai-scripts.md 3)'
        return {'routine': 'routine', 'data': 'data', 'dict': 'dictionary', 'array': 'array',
                'strtab': 'string table'}.get(self.kind.get(sid), '?')


# ------------------------------------------------------------------------------------------
# Expression nodes
# ------------------------------------------------------------------------------------------
class N:
    __slots__ = ('t', 'kids', 'txt')

    def __init__(self, txt, kids=(), t='atom'):
        self.txt, self.kids, self.t = txt, list(kids), t


def render(n):
    if n.t == 'atom':
        return n.txt
    if n.t == 'bin':
        return '(%s %s %s)' % (render(n.kids[0]), n.txt, render(n.kids[1]))
    if n.t == 'un':
        return '%s%s' % (n.txt, render(n.kids[0]))
    if n.t == 'call':
        return '%s(%s)' % (n.txt, ', '.join(render(k) for k in n.kids))
    if n.t == 'post':
        return '%s%s' % (render(n.kids[0]), n.txt)
    return n.txt


class DisErr(Exception):
    pass


# ------------------------------------------------------------------------------------------
# Disassembler for one segment
# ------------------------------------------------------------------------------------------
class Dis:
    def __init__(self, store, sid, stats):
        self.S, self.sid, self.st = store, sid, stats
        self.b = store.data[sid]
        self.kind = store.kind[sid]
        self.insns = {}         # start -> (end, mnemonic, operands, comment)
        self.owner = {}         # byte offset -> insn start
        self.blocks = {}        # start -> (end, kind, text)
        self.blk_owner = {}
        self.labels = collections.defaultdict(set)   # offset -> reasons
        self.entries = []       # (offset, reason)
        self.unknown = []       # (offset, opcode, context)
        self.anoms = []         # (offset, text)
        self.unreached = []     # (start, end) runs of code found only by the gap sweep
        self.dead = set()       # insn starts decoded by the gap sweep
        self.rawgaps = []       # (start, end) bytes left undecoded
        self.methods = {}       # offset -> [selector,...]
        self.props = []         # (selector, rendered value)
        self.dict_info = None

    # --- references ---
    def vaddr(self, v, where, ctx='literal'):
        """Render a VAddr literal and record cross references."""
        t = tag_of(v)
        S, st = self.S, self.st
        if t == 0:
            return str(s28(v))
        if t == 1:
            if ctx.startswith('literal@'):
                # 0x43 rebases a tag-1 value onto the frame's locals base (DoExpr case 0x43):
                # it is the address of local slot lo
                return '&L%02X' % (v & 0xFFFF) if (v & 0xFFFF) < 0x30 else '&slot(%d)' % (v & 0xFFFF)
            return 'slot(%d)' % (v & 0xFFFF)
        if t == 2:
            g = v & 0xFFFF
            return 'globstr(%d%s)' % (g, ':' + GLOBSTR[g] if g in GLOBSTR else '')
        if t == 3:
            sid, idx = v & 0xFFFF, (v >> 16) & 0xFFF
            st['xref_str'][sid] += 1
            s, note = S.string_ref(sid, idx)
            if s is None:
                self.anoms.append((where, 'string ref %04X[%d]: %s' % (sid, idx, note)))
                st['str_unresolved'] += 1
                return 'str[%04X:%d]' % (sid, idx)
            st['str_resolved'] += 1
            if note.startswith('entry'):
                st['str_nilbase'] += 1
                return 'str[%04X:%d]<Nil entry: index base>' % (sid, idx)
            if note:
                self.anoms.append((where, 'string ref %04X[%d] %s' % (sid, idx, note)))
            return 'str[%04X:%d]%s' % (sid, idx, show_text(s, 60))
        if t == 4:
            cls, oid = (v >> 16) & 0xFFF, v & 0xFFFF
            if v & 0x1000000:
                return 'sysobj(%s,%d)' % (SYS_CLASSES.get(cls & 0xFF, '%X' % cls), oid)
            nm = CLASSES.get(cls, 'cls%02X' % cls)
            extra = ''
            if cls == 0x40 and oid in S.char_names:
                extra = show_text(S.char_names[oid], 24)
            if cls not in (0x00, 0x50):
                tgt = 0x1000 + cls * 0x20 + oid
                st['xref_obj'][tgt] += 1
            return '%s#%d%s' % (nm, oid, extra)
        if t == 5:
            return {0x5000FFFF: 'Nil', 0x50000001: 'True', 0x50000000: 'False',
                    0x5000FFFE: 'Unset'}.get(v, 'const(0x%08X)' % v)
        if t == 6:
            st['xref_call'][v & 0xFFFF] += 1
            return 'routine(%04X)' % (v & 0xFFFF)
        if t == 7:
            return 'heap#%d' % (v & 0xFFFF)
        # code pointer
        sid, off = (v >> 16) & 0x7FFF, v & 0xFFFF
        if sid == self.sid:
            self.target(off, where, ctx)
            return '@%04X' % off
        st['xref_ptr'][sid] += 1
        return '@%04X:%04X' % (sid, off)

    def target(self, off, where, ctx):
        """A same-segment code pointer: classify the target by its first byte (At/Len typing)."""
        b = self.b
        if off >= len(b):
            self.anoms.append((where, 'pointer @%04X past end' % off))
            return
        c = b[off]
        if 0x80 <= c <= 0x8F:
            self.entries.append((off, ctx))
            self.labels[off].add(ctx)
        else:
            self.block(off, where)

    def block(self, off, where, length=None):
        """Parse an in-segment literal block (string / array / dictionary)."""
        if off in self.blocks:
            return self.blocks[off][0]
        b = self.b
        c = b[off]
        if c < 0x80:
            s, e = cstr(b, off)
            end = e + 1 if e < len(b) else e
            self.add_block(off, end, 'string', show_text(s))
        elif 0x90 <= c <= 0x9F:
            n = u16(b, off) & 0xFFF
            end = off + 2 + 4 * n
            if end > len(b):
                self.anoms.append((off, 'array runs past end'))
                end = len(b)
                n = (end - off - 2) // 4
            self.add_block(off, end, 'array', 'array[%d]' % n)
            items = []
            for i in range(n):
                items.append(self.vaddr(u32(b, off + 2 + 4 * i), off + 2 + 4 * i, 'array@%04X' % off))
            self.blocks[off] = (end, 'array', 'array[%d] = [%s]' % (n, ', '.join(items)))
        elif 0xA0 <= c <= 0xAF:
            n = u16(b, off) & 0xFFF
            end = off + 2 + 6 * n
            if end > len(b):
                self.anoms.append((off, 'dict runs past end'))
                end = len(b)
                n = (end - off - 2) // 6
            self.add_block(off, end, 'dict', 'dict[%d]' % n)
            ents = []
            for i in range(n):
                v = u32(b, off + 2 + 6 * i)
                k = u16(b, off + 6 + 6 * i)
                if v == 0x5000FFFF:
                    continue   # empty slot (key bytes are don't-care)
                ents.append((k, v, off + 2 + 6 * i))
            out = []
            for k, v, w in sorted(ents):
                kn = '%d%s' % (k, '/' + SELECTORS[k] if k in SELECTORS else '')
                out.append('%s: %s' % (kn, self.vaddr(v, w, 'key %s' % kn)))
            self.blocks[off] = (end, 'dict', 'dict[%d] {%s}' % (n, ', '.join(out)))
            return end
        else:
            end = off + (length or 1)
            self.add_block(off, end, 'odd', 'block starting 0x%02X (At returns operand unchanged)' % c)
            self.anoms.append((off, 'literal block with header byte 0x%02X' % c))
        return self.blocks[off][0]

    def add_block(self, start, end, kind, text):
        self.blocks[start] = (end, kind, text)
        for i in range(start, end):
            self.blk_owner.setdefault(i, start)

    # --- expressions ---
    def expr(self, pc, where):
        """Parse one RPN expression starting at pc (terminated by 0x40). Returns (pc, [nodes])."""
        b, st = self.b, self.st
        stack = []

        def pop():
            if stack:
                return stack.pop()
            self.anoms.append((pc0, 'expression stack underflow'))
            return N('?')

        while True:
            if pc >= len(b):
                raise DisErr('expression runs past end of segment')
            pc0 = pc
            op = b[pc]
            pc += 1
            st['expr_ops'][op] += 1
            if op == 0x40:
                return pc, stack
            if op < 0x30:
                stack.append(N('L%02X' % op))
            elif op < 0x40:
                stack.append(N('A%02X' % op))
            elif op == 0x41:
                v = b[pc] - 256 if b[pc] >= 0x80 else b[pc]
                pc += 1
                stack.append(N(str(v)))
            elif op == 0x42:
                v = u16(b, pc)
                v = v - 0x10000 if v & 0x8000 else v
                pc += 2
                stack.append(N(str(v)))
            elif op == 0x43:
                if pc + 4 > len(b):
                    raise DisErr('0x43 literal past end')
                v = u32(b, pc)
                stack.append(N(self.vaddr(v, pc, 'literal@%04X' % pc0)))
                pc += 4
            elif op == 0x44:
                s, e = cstr(b, pc)
                if e >= len(b):
                    raise DisErr('0x44 string unterminated')
                stack.append(N(show_text(s)))
                pc = e + 1
            elif op == 0x45:
                ln = u16(b, pc)
                pc += 2
                if pc + ln > len(b):
                    raise DisErr('0x45 block past end')
                end = self.block(pc, pc0, ln)
                if end > pc + ln:
                    self.anoms.append((pc0, '0x45 block parses longer than its length'))
                stack.append(N('blk@%04X' % pc))
                for i in range(pc, pc + ln):
                    self.blk_owner.setdefault(i, pc)
                pc += ln
            elif op == 0x46:
                i = pop()
                l = pop()
                stack.append(N('[]', [l, i], 'idx'))
                stack[-1].t = 'atom'
                stack[-1].txt = '%s[%s]' % (render(l), render(i))
            elif op == 0x47:
                off = u16(b, pc)
                pc += 2
                stack.append(N('seg[%04X]' % off))
                self.word(off, pc0)
            elif op == 0x48:
                g = b[pc]
                pc += 1
                self.st['glob_r'][g] += 1
                stack.append(N('G%02X%s' % (g, ':' + GLOBALS[g] if g in GLOBALS else '')))
            elif op == 0x49:
                s, off = u16(b, pc), u16(b, pc + 2)
                pc += 4
                st['xref_glob'][s] += 1
                st['xref_glob_off'][(s, off)] += 1
                stack.append(N('seg%04X[%04X]' % (s, off)))
            elif op in BINOPS:
                r = pop()
                l = pop()
                stack.append(N(BINOPS[op], [l, r], 'bin'))
            elif op in UNOPS:
                stack.append(N(UNOPS[op], [pop()], 'un'))
            elif op == 0x5F:
                stack.append(N('len', [pop()], 'call'))
            elif op == 0x60:
                sel = b[pc]
                pc += 1
                self.st['sel_test'][sel] += 1
                stack.append(N('has', [pop(), N(self.selname(sel))], 'call'))
            elif op == 0x61:
                sel, idx = b[pc], b[pc + 1]
                pc += 2
                self.st['sel_test'][sel] += 1
                stack.append(N('prop', [pop(), N(self.selname(sel)), N(str(idx))], 'call'))
            elif op == 0x62:
                f = b[pc]
                pc += 1
                self.st['field_r'][f] += 1
                stack.append(N('.' + self.fieldname(f), [pop()], 'post'))
            elif op == 0x63:
                c = b[pc]
                pc += 1
                stack.append(N('as_%s' % self.clsname(c), [pop()], 'call'))
            elif op == 0x64:
                c = b[pc]
                pc += 1
                stack.append(N('is_%s' % self.clsname(c), [pop()], 'call'))
            elif 0x9B <= op <= 0x9F or (0xA0 <= op <= 0xFE):
                pc, node = self.callform(op, pc, pc0)
                stack.append(node)
            else:
                st['unknown'][op] += 1
                self.unknown.append((pc0, op, 'expression'))
                raise DisErr('unknown expression opcode 0x%02X' % op)

    def callform(self, op, pc, pc0):
        """0x9B..0x9F and builtins; shared by statements and expressions."""
        b = self.b
        if op == 0x9B:
            c = b[pc]
            pc += 1
            pc, args = self.expr(pc, pc0)
            if c == 0:
                return pc, N('id_of', args, 'call')
            return pc, N('sysnew_%s' % SYS_CLASSES.get(c, '%02X' % c), args, 'call')
        if op == 0x9C:
            s = u16(b, pc)
            pc += 2
            pc, e1 = self.expr(pc, pc0)
            pc, args = self.expr(pc, pc0)
            if s == 0xFFFF:
                tgt = ', '.join(render(x) for x in e1)
                self.st['computed_calls'].append((self.sid, pc0, None))
                return pc, N('callx[%s]' % tgt, args, 'call')
            # seg + int(expr): resolve when the expression is a constant integer
            if len(e1) == 1 and e1[0].t == 'atom' and e1[0].txt.lstrip('-').isdigit():
                t = (s + int(e1[0].txt)) & 0xFFFF
                self.st['xref_call'][t] += 1
                return pc, N('R%04X' % t, args, 'call')
            self.st['xref_call_base'][s] += 1
            self.st['computed_calls'].append((self.sid, pc0, s))
            return pc, N('R[%04X+%s]' % (s, ', '.join(render(x) for x in e1)), args, 'call')
        if op == 0x9D:
            sel = b[pc]
            pc += 1
            self.st['sel_send'][sel] += 1
            pc, args = self.expr(pc, pc0)
            if not args:
                self.anoms.append((pc0, 'send with no receiver'))
                return pc, N('send_%s' % self.selname(sel), args, 'call')
            recv = args[0]
            return pc, N('%s.%s' % (render(recv), self.selname(sel)), args[1:], 'call')
        if op == 0x9E:
            off = u16(b, pc)
            pc += 2
            pc, args = self.expr(pc, pc0)
            self.entries.append((off, 'callsub@%04X' % pc0))
            self.labels[off].add('sub')
            return pc, N('sub_%04X' % off, args, 'call')
        if op == 0x9F:
            s = u16(b, pc)
            pc += 2
            pc, args = self.expr(pc, pc0)
            self.st['xref_call'][s] += 1
            return pc, N('R%04X' % s, args, 'call')
        # builtin
        pc, args = self.expr(pc, pc0)
        name = BUILTINS[op][0]
        self.st['builtin'][op] += 1
        self.st['builtin_argc'][(op, len(args))] += 1
        return pc, N(name, args, 'call')

    def word(self, off, where):
        if off + 4 > len(self.b):
            self.anoms.append((where, 'segment word @%04X past end' % off))
            return
        if off not in self.blocks:
            self.add_block(off, off + 4, 'word', 'word 0x%08X' % u32(self.b, off))

    def selname(self, s):
        return 'sel%d%s' % (s, '/' + SELECTORS[s] if s in SELECTORS else '')

    def clsname(self, c):
        return CLASSES.get(c, 'cls%02X' % c)

    def fieldname(self, f):
        n = FIELDS_PROP.get(f) or FIELDS_CHAR.get(f)
        return 'f%02X%s' % (f, ':' + n if n else '')

    # --- statements ---
    def stmt(self, pc):
        """Decode one statement. Returns (end, mnemonic, operand-text, comment, succ, terminal)."""
        b, st = self.b, self.st
        op = b[pc]
        st['stmt_ops'][op] += 1
        p = pc + 1
        succ = []
        term = False
        com = ''
        if op == 0x00:
            return p, 'nop', '', '', succ, False
        if op < 0x80:
            s, e = cstr(b, pc, stop_high=True)   # GetString: stops at NUL or any byte >= 0x80
            return e, 'text', show_text(s), '', succ, False
        if op in INVALID_STMT:
            st['unknown'][op] += 1
            self.unknown.append((pc, op, 'statement'))
            raise DisErr('invalid statement opcode 0x%02X' % op)
        mn = STMT_NAMES.get(op)
        if op == 0x81:
            a, n = b[p], b[p + 1]
            return p + 2, 'frame', 'args=%d locals=%d' % (a, n), '', succ, False
        if op == 0x82:
            slot = b[p]
            p += 1
            if slot >= 0x40:
                self.anoms.append((pc, '0x82 slot 0x%02X >= 0x40: engine evaluates nothing' % slot))
                return p, mn, 'slot 0x%02X (no-op)' % slot, '', succ, False
            p, v = self.expr(p, pc)
            nm = ('L%02X' % slot) if slot < 0x30 else ('A%02X' % slot)
            return p, mn, '%s = %s' % (nm, self.one(v, pc)), com, succ, False
        if op == 0x83:
            off = u16(b, p)
            p, v = self.expr(p + 2, pc)
            self.word(off, pc)
            return p, mn, 'seg[%04X] = %s' % (off, self.one(v, pc)), 'not persisted', succ, False
        if op == 0x84:
            p, l = self.expr(p, pc)
            p, i = self.expr(p, pc)
            p, v = self.expr(p, pc)
            return p, mn, '%s[%s] = %s' % (self.one(l, pc), self.one(i, pc), self.one(v, pc)), '', succ, False
        if op == 0x85:
            s, off = u16(b, p), u16(b, p + 2)
            p, v = self.expr(p + 4, pc)
            st['xref_glob'][s] += 1
            st['xref_glob_w'][s] += 1
            st['xref_glob_off'][(s, off)] += 1
            return p, mn, 'seg%04X[%04X] = %s' % (s, off, self.one(v, pc)), 're-saved encrypted', succ, False
        if op == 0x86:
            f = b[p]
            self.st['field_w'][f] += 1
            p, o = self.expr(p + 1, pc)
            p, v = self.expr(p, pc)
            return p, mn, '%s.%s = %s' % (self.one(o, pc), self.fieldname(f), self.one(v, pc)), '', succ, False
        if op == 0x87:
            g = b[p]
            self.st['glob_w'][g] += 1
            p, v = self.expr(p + 1, pc)
            return p, mn, 'G%02X%s = %s' % (g, ':' + GLOBALS[g] if g in GLOBALS else '', self.one(v, pc)), '', succ, False
        if op == 0x88:
            t = u16(b, p)
            self.jump(t, pc)
            return p + 2, mn, '-> %04X' % t, '', [t], True
        if op == 0x89:
            p, v = self.expr(p, pc)
            n = u16(b, p)
            p += 2
            tabs = [u16(b, p + 2 * i) for i in range(n)]
            p += 2 * n
            for t in tabs:
                self.jump(t, pc)
            return p, mn, '%s in [%s]' % (self.one(v, pc), ', '.join('%04X' % t for t in tabs)), 'else fall through', tabs, False
        if op in (0x8A, 0x8B, 0x93):
            p, v = self.expr(p, pc)
            return p, mn, self.one(v, pc), '', succ, op == 0x8B
        if op in (0x8C, 0x8D):
            p, v = self.expr(p, pc)
            t = u16(b, p)
            self.jump(t, pc)
            return p + 2, mn, '%s -> %04X' % (self.one(v, pc), t), '', [t], False
        if op == 0x8E:
            return p, mn, '', 'read a line into the input buffer', succ, False
        if op == 0x8F:
            s, e = cstr(b, p, stop_high=True)
            if e >= len(b):
                raise DisErr('0x8F string past end')
            return e + 1, mn, show_text(s), '', succ, False
        if op == 0x90:
            words = []
            q = p
            while True:
                w = bytearray()
                c = b[q]
                q += 1
                while c != 0 and c != 0x2C and c < 0x80:
                    w.append(c)
                    c = b[q]
                    q += 1
                words.append(bytes(w))
                if c != 0x2C:
                    break
            if c != 0:
                self.anoms.append((pc, '0x90 word list terminated by 0x%02X' % c))
            t = u16(b, q)
            self.jump(t, pc)
            return q + 2, mn, '%s else -> %04X' % (','.join(show_text(w)[1:-1] for w in words), t), '', [t], False
        if op == 0x91:
            return p, mn, '', 'no-op', succ, False
        if op == 0x92:
            code = b[p]
            p, v = self.expr(p + 1, pc)
            return p, mn, '%d, %s' % (code, self.one(v, pc)), 'non-local exit', succ, True
        # 0x9B..0x9F, builtins
        p, node = self.callform(op, p, pc)
        if op == 0x9C and node.txt.startswith('R') and not node.txt.startswith('R['):
            mn = 'call'
        return p, ('builtin' if op >= 0xA0 else mn), render(node), '', succ, False

    def one(self, vals, where):
        if len(vals) == 1:
            return render(vals[0])
        if not vals:
            self.anoms.append((where, 'expression pushes no value'))
            return '<none>'
        self.anoms.append((where, 'expression leaves %d values' % len(vals)))
        return '<%s>' % ', '.join(render(v) for v in vals)

    def jump(self, t, where):
        if t >= len(self.b):
            self.anoms.append((where, 'jump target %04X past end' % t))
            return
        self.entries.append((t, 'jump@%04X' % where))
        self.labels[t].add('jump')

    # --- traversal ---
    def run(self):
        b = self.b
        if self.kind == 'class':
            off = u16(b, 0)
            self.add_block(0, 2, 'hdr', 'dictionary offset = %04X' % off)
            self.dict_info = off
            self.block(off, 0)
            # method/property map for the header
            n = u16(b, off) & 0xFFF
            for i in range(n):
                v = u32(b, off + 2 + 6 * i)
                k = u16(b, off + 6 + 6 * i)
                if v == 0x5000FFFF:
                    continue
                if tag_of(v) == -1 and (v >> 16) & 0x7FFF == self.sid and (v & 0xFFFF) < len(b) \
                        and 0x80 <= b[v & 0xFFFF] <= 0x8F:
                    self.methods.setdefault(v & 0xFFFF, []).append(k)
                    self.st['sel_method'][k] += 1
                else:
                    self.props.append(k)
                    self.st['sel_prop'][k] += 1
        elif self.kind == 'routine':
            self.entries.append((0, 'entry'))
            self.labels[0].add('entry')
        elif self.kind == 'strtab':
            n = u16(b, 0) & 0xFFF
            hi = collections.Counter(u32(b, 2 + 4 * i) >> 16 for i in range(n)
                                     if u32(b, 2 + 4 * i) != 0x5000FFFF)
            self.add_block(0, 2 + 4 * n, 'strtab', 'string table, %d entries (VAddrToPtr case 3 uses '
                           'only the low 16 bits; high halves seen: %s)' % (
                               n, ', '.join('%04X×%d' % kv for kv in sorted(hi.items()))))
            for i in range(n):
                v = u32(b, 2 + 4 * i)
                if v == 0x5000FFFF:
                    continue
                o = v & 0xFFFF
                if o not in self.blocks:
                    sb, e = cstr(b, o)
                    self.add_block(o, e + 1, 'string', '[%d] %s' % (i, show_text(sb)))
                else:
                    e, k, t = self.blocks[o]
                    self.blocks[o] = (e, k, '[%d] ' % i + t)
        elif self.kind in ('dict', 'array'):
            self.block(0, 0)
        self.trace()
        self.gaps()
        run = None
        for o in sorted(self.insns):
            if o in self.dead:
                if run and run[1] == o:
                    run[1] = self.insns[o][0]
                else:
                    run = [o, self.insns[o][0]]
                    self.unreached.append(run)
            else:
                run = None
        self.unreached = [tuple(r) for r in self.unreached]
        return self

    def trace(self, dead=False):
        b = self.b
        while self.entries:
            off, why = self.entries.pop()
            pc = off
            while pc < len(b):
                if pc in self.insns:
                    break
                if pc in self.owner and self.insns[self.owner[pc]][1] != 'text':
                    self.anoms.append((pc, 'control reaches the middle of instruction @%04X (%s)' % (self.owner[pc], why)))
                    break
                if pc in self.blk_owner and self.blocks.get(self.blk_owner[pc], (0, ''))[1] != 'word':
                    self.anoms.append((pc, 'control falls into literal block @%04X' % self.blk_owner[pc]))
                    break
                try:
                    end, mn, ops, com, succ, term = self.stmt(pc)
                except DisErr as e:
                    self.insns[pc] = (pc + 1, '??', '', str(e))
                    self.owner[pc] = pc
                    self.anoms.append((pc, str(e)))
                    break
                except IndexError:
                    self.insns[pc] = (pc + 1, '??', '', 'operand past end of segment')
                    self.owner[pc] = pc
                    self.anoms.append((pc, 'operand past end of segment'))
                    self.st['unknown']['past-end'] += 1
                    self.unknown.append((pc, b[pc], 'operand past end'))
                    break
                if mn == 'text':
                    # a jump may enter a literal text in the middle: GetString then prints the
                    # tail up to the same terminator (compiler-shared tails).  Not an anomaly.
                    inner = [k for k in self.insns if pc < k < end]
                    outer = self.owner.get(pc)
                    if inner or outer is not None:
                        com = 'shares its tail with text @%04X' % (min(inner) if inner else outer)
                        self.st['text_shared'] += 1
                self.insns[pc] = (end, mn, ops, com)
                if dead:
                    self.dead.add(pc)
                for i in range(pc, end):
                    if i in self.owner and self.owner[i] != pc:
                        if not (mn == 'text' and self.insns[self.owner[i]][1] == 'text'):
                            self.anoms.append((i, 'overlapping decode with @%04X' % self.owner[i]))
                        else:
                            continue   # keep the earliest-starting text as owner
                    self.owner[i] = pc
                if term:
                    break
                pc = end

    def gaps(self):
        """Bytes neither decoded nor referenced: try them as code, else leave as raw."""
        b = self.b
        i = 0
        while i < len(b):
            if i in self.owner or i in self.blk_owner:
                i += 1
                continue
            j = i
            while j < len(b) and j not in self.owner and j not in self.blk_owner:
                j += 1
            if self.kind in ('array', 'dict', 'strtab') and (j - i) % 4 == 0:
                for k in range(i, j, 4):
                    self.add_block(k, k + 4, 'word', 'word %s (VAddr; readable by 0x49 / writable by 0x85)'
                                   % self.vaddr(u32(b, k), k, 'word'))
            elif self.kind in ('class', 'routine'):
                self.entries.append((i, 'unreferenced'))
                self.labels[i].add('unreferenced')
                self.trace(dead=True)
                if i not in self.owner:
                    self.rawgaps.append((i, j))
                    i = j
                continue        # rescan: the sweep may have covered only part of the gap
            else:
                self.rawgaps.append((i, j))
            i = j

    # --- listing ---
    def listing(self):
        S, b, sid = self.S, self.b, self.sid
        L = []
        L.append('; segment %04X  page %02X  %s' % (sid, sid >> 8, S.seg_label(sid)))
        L.append('; kind %s%s  length %d bytes  (Cythera Data, XOR-decrypted with key = segment id)'
                 % (self.kind, ' [stored plaintext]' if sid in S.plain else '', len(b)))
        if self.kind == 'class':
            meths = ', '.join('%s@%04X' % ('/'.join(self.selname(k) for k in ks), o)
                              for o, ks in sorted(self.methods.items()))
            props = ', '.join(self.selname(k) for k in sorted(self.props))
            L.append('; dictionary @%04X  methods: %s' % (self.dict_info, meths or '-'))
            L.append('; properties: %s' % (props or '-'))
        L.append('; unknown opcodes: %d   anomalies: %d   dead-code runs: %d   undecoded bytes: %d'
                 % (len(self.unknown), len(self.anoms), len(self.unreached),
                    sum(e - s for s, e in self.rawgaps)))
        for n in S.notes.get(sid, []):
            L.append('; NOTE: ' + n)
        for o, t in sorted(self.anoms):
            L.append('; ANOMALY @%04X: %s' % (o, t))
        L.append(';')
        L.append('; offset: bytes  mnemonic operands  ; comment')
        L.append('; locals L00..L2F (TInterp[1]), args A30..A3F (TInterp[0]); &Lnn = address of a local (tag-1 literal);')
        L.append('; R<seg> = routine segment; @off = code pointer; Gnn = GetGlobal; .fNN = GetField; ">" = jump target; "x" = dead code')
        starts = sorted(set(self.insns) | set(self.blocks) | {s for s, e in self.rawgaps})
        unref = {s for s, e in self.unreached}
        for o in starts:
            if o in self.methods:
                L.append('')
                L.append('; ==== method %s @%04X ====' % (', '.join(self.selname(k) for k in self.methods[o]), o))
            elif o in unref:
                e = [x for x in self.unreached if x[0] == o][0][1]
                L.append('; ---- dead code %04X-%04X: no dictionary entry, jump, pointer or call reaches it ----' % (o, e))
            elif o in self.labels and 'sub' in self.labels[o]:
                L.append('; ---- local subroutine @%04X ----' % o)
            if o in self.insns:
                end, mn, ops, com = self.insns[o]
                lab = '>' if o in self.labels and self.labels[o] & {'jump'} else ' '
                if o in self.dead:
                    lab = 'x'
                L.append(self.fmt(o, end, lab, mn, ops, com))
            elif o in self.blocks:
                end, kind, txt = self.blocks[o]
                if self.owner.get(o) is not None:
                    continue
                L.append(self.fmt(o, end, ' ', '.' + kind, txt, ''))
            else:
                for s, e in self.rawgaps:
                    if s == o:
                        for k in range(s, e, 16):
                            L.append(self.fmt(k, min(e, k + 16), ' ', '.bytes', '', 'undecoded', full=True))
        return '\n'.join(L) + '\n'

    def fmt(self, o, end, lab, mn, ops, com, full=False):
        bs = self.b[o:end]
        h = ' '.join('%02x' % x for x in bs[:12])
        if len(bs) > 12 and not full:
            h += ' …+%d' % (len(bs) - 12)
        line = '%04X:%s%-44s %-9s %s' % (o, lab, h, mn, ops)
        if com:
            line += '  ; ' + com
        return line


# ------------------------------------------------------------------------------------------
# AI segments (page 0x04): structural decode only (ai-scripts.md 3)
# ------------------------------------------------------------------------------------------
def ai_listing(S, sid):
    b = S.data[sid]
    L = ['; segment %04X  page 04  compiled combat AI (ai-scripts.md 3) — not VM bytecode, stored plain' % sid,
         '; length %d bytes  unknown opcodes: 0 (no VM opcodes in this format)' % len(b)]
    nl = b[0]
    L.append('0000: name %s' % show_text(b[1:1 + nl]))
    for o in range(0x20, len(b) - 7, 8):
        L.append('%04X: entry %s' % (o, ' '.join('%02x' % x for x in b[o:o + 8])))
    return '\n'.join(L) + '\n'


def data_listing(S, sid, st):
    b = S.data[sid]
    L = ['; segment %04X  page %02X  %s' % (sid, sid >> 8, S.seg_label(sid)),
         '; kind data (no code structure; read/written as words by 0x49 / 0x85)  length %d bytes' % len(b),
         '; referenced by 0x49 reads/0x85 writes: %d (%d writes)' % (st['xref_glob'][sid], st['xref_glob_w'][sid]),
         '; unknown opcodes: 0 (not code)']
    for n in S.notes.get(sid, []):
        L.append('; NOTE: ' + n)
    offs = sorted(o for (s, o) in st['xref_glob_off'] if s == sid)
    if offs:
        L.append('; word offsets referenced: ' + ', '.join('%04X' % o for o in offs))
    for k in range(0, len(b), 16):
        L.append('%04X:  %s' % (k, ' '.join('%02x' % x for x in b[k:k + 16])))
    return '\n'.join(L) + '\n'


# ------------------------------------------------------------------------------------------
# Driver
# ------------------------------------------------------------------------------------------
def new_stats():
    return {k: collections.Counter() for k in (
        'stmt_ops', 'expr_ops', 'builtin', 'builtin_argc', 'unknown', 'xref_str', 'xref_obj',
        'xref_call', 'xref_call_base', 'xref_ptr', 'xref_glob', 'xref_glob_w', 'xref_glob_off',
        'sel_method', 'sel_prop', 'sel_send', 'sel_test', 'field_r', 'field_w', 'glob_r', 'glob_w')} | {
        'str_resolved': 0, 'str_unresolved': 0, 'text_shared': 0, 'str_nilbase': 0, 'computed_calls': []}


STAT_COUNTERS = ('sel_method', 'sel_prop', 'sel_send', 'sel_test', 'field_r', 'field_w', 'glob_r', 'glob_w')


def run_all(S, only=None):
    st = new_stats()
    results = {}
    code_kinds = ('class', 'routine', 'strtab', 'dict', 'array')
    for sid in sorted(S.kind):
        if only and sid not in only:
            continue
        if S.kind[sid] in code_kinds:
            results[sid] = Dis(S, sid, st).run()
    return st, results


def coverage(r):
    """Unique byte coverage of one Dis result."""
    ins = set(r.owner)
    dead = set()
    for o in r.dead:
        dead.update(range(o, r.insns[o][0]))
    blk = set(r.blk_owner) - ins
    raw = set()
    for s_, e in r.rawgaps:
        raw.update(range(s_, e))
    return len(ins - dead), len(dead), len(blk), len(raw)


def census(S, st, results, outdir):
    L = []
    w = L.append
    pipe = lambda t: t.replace('|', '\\|')
    w('# Cythera 1.0.4 — script census (tool output)')
    w('')
    w('Generated by `python3 docs/cythera/tools/scriptdis.py --census docs/cythera/script-census.md`'
      ' (stdlib only). It reads the `Cythera Data` data fork, decrypts every segment of pages'
      ' 0x01–0x3F with `seg.py dec()` (key = segment id; script segments are not LZ-coded) and'
      ' disassembles them; per-segment listings go to `%s/<segid>.txt` (git-ignored). Register:'
      ' **mechanical tool output**. The decoder implements script-vm.md as corrected by the'
      ' 2026-10-03 review (0x53 `!=`, 0x54 `==`; slots 0x00–0x2F locals, 0x30–0x3F args; 0x9C'
      ' `seg16 <int-expr> <args>`), checked operand by operand against `DoExpr__7TInterpFRPUc @'
      ' 1007ddfc` and `DoInterpAt__7TInterpFsP5VAddr @ 10080c98` in this session\'s Ghidra dump.'
      ' Field/global names come from `GetField__Fsss @ 100921b4` / `GetGlobal__Fs @ 1009376c`.' % outdir)
    w('')
    # --- segments by page/kind
    byp = collections.defaultdict(collections.Counter)
    bytes_p = collections.Counter()
    for sid, k in S.kind.items():
        byp[sid >> 8][k] += 1
        bytes_p[sid >> 8] += len(S.data[sid])
    w('## 1. Segments in the script band (pages 0x01–0x3F)')
    w('')
    w('Kinds are measured on the decrypted bytes: `class` = u16 dictionary offset whose target is a'
      ' 0xA0–0xAF dictionary that fits; `routine` = starts with the frame op 0x81; `strtab` = 0x90–0x9F'
      ' array whose non-Nil entries point (low 16 bits) at C strings after the table; `dict` / `array`'
      ' = bare literal block; `ai` = page 0x04 combat-AI records (plain, ai-scripts.md §3); `data` ='
      ' none of these.')
    w('')
    w('| page | segments | bytes | kinds |')
    w('|---|---|---|---|')
    allseg = allbytes = 0
    for p in sorted(byp):
        n = sum(byp[p].values())
        allseg += n
        allbytes += bytes_p[p]
        w('| 0x%02X | %d | %d | %s |' % (p, n, bytes_p[p], ', '.join('%s %d' % kv for kv in sorted(byp[p].items()))))
    w('| **all** | **%d** | **%d** | |' % (allseg, allbytes))
    w('')
    code_segs = sorted(s for s in results if S.kind[s] in ('class', 'routine'))
    code_bytes = sum(len(S.data[s]) for s in code_segs)
    cov = collections.Counter()
    for s_ in code_segs:
        a_, d_, b_, r_ = coverage(results[s_])
        cov['live'] += a_
        cov['dead'] += d_
        cov['blk'] += b_
        cov['raw'] += r_
    unk = sum(len(r.unknown) for r in results.values())
    anoms = sum(len(r.anoms) for r in results.values())
    w('## 2. Totals')
    w('')
    w('- **Code segments disassembled: %d** (class %d, routine %d), **%d bytes**. Plus %d literal'
      ' segments (string tables, dictionaries, arrays) decoded as data, %d data segments and %d'
      ' combat-AI segments listed structurally. Every one of the %d script-band segments has a listing.'
      % (len(code_segs), sum(1 for s_ in code_segs if S.kind[s_] == 'class'),
         sum(1 for s_ in code_segs if S.kind[s_] == 'routine'), code_bytes,
         sum(1 for s_ in results if s_ not in code_segs),
         sum(1 for k in S.kind.values() if k == 'data'), sum(1 for k in S.kind.values() if k == 'ai'),
         allseg))
    w('- Byte coverage of the code segments (unique bytes): statements reached from a dictionary'
      ' entry / routine entry / jump / pointer **%d**; statements reached only by the gap sweep'
      ' (dead code) %d; literal blocks (headers, dictionaries, arrays, strings, words) %d; left'
      ' undecoded **%d**. Sum = %d.' % (cov['live'], cov['dead'], cov['blk'], cov['raw'],
                                        cov['live'] + cov['dead'] + cov['blk'] + cov['raw']))
    w('- **UNKNOWN-OPCODE COUNT: %d** — statement 0x80 / 0x94–0x9A / 0xFF, expression 0x65–0x9A /'
      ' 0xFF, or an operand running past the segment end. Anomalies flagged in listings: %d.' % (unk, anoms))
    w('- Literal-text statements entered in the middle by a jump (GetString prints the shared tail'
      ' up to the same terminator — compiler tail sharing, not an error): %d.' % st['text_shared'])
    if unk:
        w('')
        w('Unknown opcode sites:')
        for s_, r in sorted(results.items()):
            for o, op, ctx in r.unknown:
                w('- %04X @%04X: 0x%02X (%s)' % (s_, o, op, ctx))
    w('')
    # dead code breakdown
    dc = collections.Counter()
    for s_ in code_segs:
        r = results[s_]
        for a_, e in r.unreached:
            k = r.b[a_:e]
            if k == b'\x8b\x41\x00\x40':
                dc['`8B 41 00 40` (return 0) after a final return — compiler epilogue'] += 1
            elif len(k) == 3 and k[0] == 0x88:
                dc['lone `88` goto after a return (if/else join)'] += 1
            else:
                dc['longer run (goto + body; cut or unreachable branches — see listings)'] += 1
    w('Dead-code runs (decoded by the gap sweep; no dictionary entry, jump, pointer or call reaches'
      ' them): %s.' % '; '.join('%s: %d' % kv for kv in dc.most_common()))
    w('')
    plain = sorted(S.plain)
    w('Stored plaintext in the shipped file (decrypted bytes match no structure, raw bytes do;'
      ' `GetEncryptedSegment @ 1007d148` always decrypts, so the interpreter would read garbage): %s.'
      ' No code references either (0 calls, 0 string refs, 0 pointers).' %
      ', '.join('0x%04X (%s, %d B)' % (s_, S.kind[s_], len(S.data[s_])) for s_ in plain))
    if 0x0101 in S.kind:
        r = results.get(0x0101)
        keys = []
        if r:
            b_ = S.data[0x0101]
            n = u16(b_, 0) & 0xFFF
            for i in range(n):
                v = u32(b_, 2 + 6 * i)
                if v != 0x5000FFFF:
                    keys.append((u16(b_, 6 + 6 * i), cstr(b_, v & 0xFFFF)[0]))
        sample = ', '.join('%04X→%s' % (k, v.decode('mac_roman')) for k, v in sorted(keys)
                           if k in (0x0200, 0x0201, 0x0202, 0x3000, 0x3001, 0x3006, 0x300E, 0x1700))
        w('')
        w('0x0101 is a %d-slot dictionary whose %d keys are segment ids and whose values point at'
          ' identifier strings — a compiler symbol table left in the data (e.g. %s). Its routine'
          ' numbering does **not** match the selectors native code sends (it has 0x3006 "Talk"; native'
          ' talk is selector 12 → 0x300C; script-vm.md §2.3), so it is an older build\'s table: the tool'
          ' does not use it for names.' % (u16(S.data[0x0101], 0) & 0xFFF, len(keys), sample))
    w('')
    # --- opcode histograms
    w('## 3. Opcode histogram')
    w('')
    w('Statements (one count per decoded statement, dead code included):')
    w('')
    so = st['stmt_ops']
    w('| op | name | count |')
    w('|---|---|---|')
    w('| 01–7F | literal text | %d |' % sum(v for k, v in so.items() if 0x01 <= k <= 0x7F))
    for k in sorted(so):
        if 0x01 <= k <= 0x7F or k >= 0xA0:
            continue
        w('| %02X | %s | %d |' % (k, STMT_NAMES.get(k, '?'), so[k]))
    w('| A0–FE | builtin (statement form) | %d |' % sum(v for k, v in so.items() if k >= 0xA0))
    w('')
    eo = st['expr_ops']
    names = {0x40: 'end', 0x41: 'push i8', 0x42: 'push i16', 0x43: 'push u32 VAddr', 0x44: 'inline string',
             0x45: 'inline block', 0x46: 'index', 0x47: 'segment word', 0x48: 'global', 0x49: 'other-segment word',
             0x5F: 'len', 0x60: 'has selector', 0x61: 'property element', 0x62: 'field', 0x63: 'cast',
             0x64: 'is-instance', 0x9B: 'sysnew / id_of', 0x9C: 'call routine (+int)', 0x9D: 'send',
             0x9E: 'call local sub', 0x9F: 'call routine'}
    w('Expression opcodes:')
    w('')
    w('| op | name | count |')
    w('|---|---|---|')
    w('| 00–2F | local slot | %d |' % sum(eo[k] for k in range(0, 0x30)))
    w('| 30–3F | arg slot | %d |' % sum(eo[k] for k in range(0x30, 0x40)))
    for k in sorted(eo):
        if 0x40 <= k < 0xA0:
            nm = names.get(k) or BINOPS.get(k) or UNOPS.get(k) or '?'
            w('| %02X | %s | %d |' % (k, pipe(nm), eo[k]))
    w('| A0–FE | builtin (expression form) | %d |' % sum(eo[k] for k in range(0xA0, 0xFF)))
    w('')
    # --- builtins
    w('## 4. Builtin calls, by name (statement + expression form)')
    w('')
    w('"arg counts seen" = number of values the argument expression pushed (count×occurrences);'
      ' iterators legitimately vary (mode 0 passes the init arguments, modes 1/2 only slot+mode).')
    w('')
    w('| op | name | calls | arg counts seen | banked args |')
    w('|---|---|---|---|---|')
    for op in range(0xA0, 0xFF):
        c = st['builtin'][op]
        argc = sorted((n, v) for (o, n), v in st['builtin_argc'].items() if o == op)
        w('| %02X | %s | %d | %s | %s |' % (op, BUILTINS[op][0], c,
                                            ' '.join('%d×%d' % (n, v) for n, v in argc) or '—',
                                            pipe(BUILTINS[op][1])))
    w('')
    never = [BUILTINS[op][0] for op in range(0xA0, 0xFF) if st['builtin'][op] == 0]
    w('Total builtin calls: %d. Never called by the shipped scripts (%d): %s.' % (
        sum(st['builtin'].values()), len(never), ', '.join(never)))
    w('')
    mism = []
    for (op, n), v in sorted(st['builtin_argc'].items()):
        bank = BUILTINS[op][1]
        want = 0 if bank == '()' else bank.count(',') + 1
        if n != want and not BUILTINS[op][0].startswith('iterate'):
            mism.append('%02X %s %d×%d (banked %d)' % (op, BUILTINS[op][0], n, v, want))
    w('Non-iterator builtins called with an argument count different from the banked list: %s.'
      % ('; '.join(mism) or 'none'))
    w('')
    # --- selectors / fields / globals
    w('## 5. Selectors, fields, globals')
    w('')
    w('Selectors defined in class dictionaries (methods = code pointers to a 0x8x byte; properties ='
      ' any other value) and selectors sent with 0x9D / tested with 0x60 / read with 0x61:')
    w('')
    w('| sel | banked name | methods | properties | 0x9D sends | 0x60/0x61 uses |')
    w('|---|---|---|---|---|---|')
    sels = set(st['sel_method']) | set(st['sel_prop']) | set(st['sel_send']) | set(st['sel_test'])
    for k in sorted(sels):
        w('| %d | %s | %d | %d | %d | %d |' % (k, SELECTORS.get(k, ''), st['sel_method'][k], st['sel_prop'][k],
                                              st['sel_send'][k], st['sel_test'][k]))
    w('')
    w('Fields (0x62 read / 0x86 write), name from GetField/SetField: %s.' % ', '.join(
        '%02X%s %d/%d' % (f, ':' + (FIELDS_PROP.get(f) or FIELDS_CHAR.get(f) or '?'), st['field_r'][f], st['field_w'][f])
        for f in sorted(set(st['field_r']) | set(st['field_w']))))
    w('')
    w('Globals (0x48 read / 0x87 write): %s.' % ', '.join(
        '%02X%s %d/%d' % (g, ':' + GLOBALS.get(g, '?'), st['glob_r'][g], st['glob_w'][g])
        for g in sorted(set(st['glob_r']) | set(st['glob_w']))))
    w('')
    # --- strings
    w('## 6. String tables (page 0x02)')
    w('')
    w('| seg | entries | Nil entries | bytes | tag-3 refs from code | entry-pointer high halves |')
    w('|---|---|---|---|---|---|')
    for sid in sorted(s_ for s_ in S.kind if s_ >> 8 == 0x02):
        b_ = S.data[sid]
        n = u16(b_, 0) & 0xFFF
        vals = [u32(b_, 2 + 4 * i) for i in range(n)]
        hi = collections.Counter(v >> 16 for v in vals if v != 0x5000FFFF)
        w('| %04X%s | %d | %d | %d | %d | %s |' % (sid, ' (plain)' if sid in S.plain else '', n,
                                                 sum(1 for v in vals if v == 0x5000FFFF), len(b_),
                                                 st['xref_str'][sid],
                                                 ', '.join('%04X' % h for h in sorted(hi))))
    w('')
    other = {s_: v for s_, v in st['xref_str'].items() if s_ >> 8 != 0x02}
    w('Tag-3 string references from code and literal data: %d resolved (of which %d point at a Nil'
      ' entry 0 and are used as `str + int` index bases), %d unresolved; references outside page'
      ' 0x02: %s. Entry high halves are `8000|seg` code pointers except 0x0201 (`9165`, never'
      ' decoded by VAddrToPtr case 3, which uses only the low 16 bits). 0x0201 is read natively by'
      ' `GetCharacterName` (`id<<16|0x30000201`); 0x0203–0x0206 (archetype names/descriptions/stats/'
      'skills) and 0x0210 have no tag-3 reference in script code.' % (
          st['str_resolved'], st['str_nilbase'], st['str_unresolved'],
          ', '.join('%04X×%d' % kv for kv in sorted(other.items())) or 'none'))
    w('')
    # --- open pages
    w('## 7. Open pages 0x01, 0x03, 0x05, 0x08, 0x0A–0x0F — measured')
    w('')
    w('`decoded` = unique bytes covered by statements + literal blocks / segment bytes; `calls in` ='
      ' static routine calls into the page from all disassembled code (0x9F, 0x9C with a constant'
      ' offset, tag-6 literals); `computed` = 0x9C sites whose base segment lies in the page.')
    w('')
    w('| page | segs | bytes | kinds | decoded | unknown | calls in | segs never called statically | computed |')
    w('|---|---|---|---|---|---|---|---|---|')
    calls_p = collections.Counter()
    for s_, v in st['xref_call'].items():
        calls_p[s_ >> 8] += v
    comp_p = collections.Counter()
    for sid, off, base in st['computed_calls']:
        if base is not None:
            comp_p[base >> 8] += 1
    for p in (0x01, 0x03, 0x05, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x30):
        sids = sorted(s_ for s_ in S.kind if s_ >> 8 == p)
        if not sids:
            continue
        nb = sum(len(S.data[s_]) for s_ in sids)
        dec = 0
        for s_ in sids:
            r = results.get(s_)
            if r:
                dec += len(set(r.owner) | set(r.blk_owner))
        unk_p = sum(len(results[s_].unknown) for s_ in sids if s_ in results)
        uncalled = [s_ for s_ in sids if st['xref_call'][s_] == 0 and S.kind[s_] == 'routine']
        w('| 0x%02X | %d | %d | %s | %d/%d | %d | %d | %s | %d |' % (
            p, len(sids), nb, ', '.join('%s %d' % kv for kv in sorted(byp[p].items())), dec, nb, unk_p,
            calls_p[p], ('%d: ' % len(uncalled) + ' '.join('%04X' % x for x in uncalled)) if uncalled else '0',
            comp_p[p]))
    w('')
    w('Computed routine calls (0x9C) — the only way the uncalled segments above can be reached from'
      ' script code:')
    w('')
    for sid, off, base in sorted(st['computed_calls']):
        r = results[sid]
        ins = r.insns.get(r.owner.get(off, off))
        w('- %04X @%04X: %s' % (sid, off, ('`%s %s`' % (ins[1], pipe(ins[2]))) if ins else '?'))
    w('')
    w('Data pages (0x49 reads / 0x85 writes, by segment and word offset):')
    w('')
    for sid in sorted(s_ for s_ in S.kind if (s_ >> 8) in (0x01, 0x03, 0x05)):
        offs = sorted(o for (s_, o) in st['xref_glob_off'] if s_ == sid)
        w('- %04X (%s, %d B): %d refs (%d writes)%s' % (
            sid, S.kind[sid] + (' plain' if sid in S.plain else ''), len(S.data[sid]),
            st['xref_glob'][sid], st['xref_glob_w'][sid],
            ('; offsets ' + ', '.join('%04X×%d' % (o, st['xref_glob_off'][(sid, o)]) for o in offs)) if offs else ''))
    other = sorted(s_ for s_ in st['xref_glob'] if (s_ >> 8) not in (0x01, 0x03, 0x05))
    w('')
    w('0x49/0x85 references to segments outside pages 0x01/0x03/0x05: %s.' % (
        ', '.join('%04X×%d' % (s_, st['xref_glob'][s_]) for s_ in other) or 'none'))
    missing = sorted(s_ for s_ in st['xref_call'] if s_ not in S.kind)
    w('')
    w('Static call targets with no segment in the shipped data: %s.' % (
        ', '.join('%04X' % s_ for s_ in missing) or 'none'))
    w('')
    return '\n'.join(L) + '\n', dict(segments=len(code_segs), bytes=code_bytes, unknown=unk,
                                     allseg=allseg, allbytes=allbytes)


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--data', default=DEFAULT_DATA, help='path to "Cythera Data" (data fork)')
    ap.add_argument('--out', default=None,
                    help='directory for per-segment listings <segid>.txt (default: ghidra/cythera-scripts)')
    ap.add_argument('--seg', nargs='*', default=None, help='only these segment ids (hex), e.g. 1802 3000')
    ap.add_argument('--census', nargs='?', const='-', default=None,
                    help='write the census markdown to FILE (default stdout)')
    ap.add_argument('--stdout', action='store_true', help='print listings to stdout instead of files')
    ap.add_argument('--quiet', action='store_true')
    a = ap.parse_args(argv)
    repo = os.path.abspath(os.path.join(HERE, '..', '..', '..'))
    out = a.out or os.path.join(repo, 'ghidra', 'cythera-scripts')
    S = Store(a.data)
    only = {int(x, 16) for x in a.seg} if a.seg else None
    st, results = run_all(S, None)   # always analyse everything (xrefs need the whole corpus)
    sids = sorted(s for s in S.kind if not only or s in only)
    if not a.stdout:
        os.makedirs(out, exist_ok=True)
    for sid in sids:
        if sid in results:
            text = results[sid].listing()
        elif S.kind[sid] == 'ai':
            text = ai_listing(S, sid)
        else:
            text = data_listing(S, sid, st)
        if a.stdout:
            sys.stdout.write(text)
        else:
            with open(os.path.join(out, '%04x.txt' % sid), 'w') as f:
                f.write(text)
    rel = os.path.relpath(out, repo) if out.startswith(repo) else out
    md, tot = census(S, st, results, rel)
    if a.census:
        if a.census == '-':
            sys.stdout.write(md)
        else:
            with open(a.census, 'w') as f:
                f.write(md)
    if not a.quiet:
        sys.stderr.write('scriptdis: %d listings -> %s; code segments %d, code bytes %d, unknown opcodes %d\n'
                         % (len(sids), 'stdout' if a.stdout else out, tot['segments'], tot['bytes'], tot['unknown']))
    return 0


if __name__ == '__main__':
    sys.exit(main())
