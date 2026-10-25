"""Check every native hook target against a game exe before a release (the relocation framework's offline half).

  python -I tools/check_hooks.py <unpacked exe> [native source dir]

The targets are read from the native sources themselves - every scan::FunctionUsing("anchor", "prologue") and
appearance's Hook(L"what", "anchor", "prologue", ...) - so there is one list, the code's. Each is resolved the way
scan.h does it at runtime: the exact ASCII string (NUL-terminated, NUL before it) in the non-executable sections ->
every RIP-relative disp32 in the executable sections that points at it -> the function containing that reference
(.pdata, chained unwind entries followed) -> the functions whose first bytes match the prologue. Exactly one = OK;
none = NOT FOUND; several = AMBIGUOUS (the runtime refuses those too). Exit status 1 if any target fails.

The second, independent anchor (appearance.cpp's Hook): in a file with a literal FunctionUsing target (the full
build), every Hook target must be reachable from it within two calls (E8 / E9 rel32 in each function's body: its unwind
entry + the contiguous entries chained to it) - scan::Reaches, which the runtime checks before hooking. Not reached =
ANCHORS DISAGREE.

Addresses print as file virtual addresses (image base 0x140000000), as tools/exe_dis.py / xref.py use."""
import bisect
import glob
import os
import re
import struct
import sys

import numpy as np
import pefile

HERE = os.path.dirname(os.path.abspath(__file__))
exe = sys.argv[1]
src_dir = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, '..', 'native', 'WaCaNative', 'src')

# --- the targets, from the sources --------------------------------------------------------------------------------
CALLS = [
    re.compile(r'FunctionUsing\(\s*"((?:[^"\\]|\\.)*)"\s*,\s*"([0-9A-Fa-f? ]+)"\s*\)'),
    re.compile(r'Hook\(\s*L"([^"]*)"\s*,\s*"((?:[^"\\]|\\.)*)"\s*,\s*"([0-9A-Fa-f? ]+)"'),
]
targets = []   # (where, label, anchor, prologue, kind: 'hook' | 'root')
for path in sorted(glob.glob(os.path.join(src_dir, '*.cpp'))):
    text = open(path, encoding='utf-8').read()
    for m in CALLS[1].finditer(text):
        line = text.count('\n', 0, m.start()) + 1
        targets.append((f'{os.path.basename(path)}:{line}', m.group(1), m.group(2), m.group(3), 'hook'))
    # literal calls only: the generic call inside Hook() passes variables, which the regex doesn't match
    for m in CALLS[0].finditer(text):
        line = text.count('\n', 0, m.start()) + 1
        targets.append((f'{os.path.basename(path)}:{line}', m.group(1), m.group(1), m.group(2), 'root'))
if not targets:
    sys.exit(f'no hook targets found in {src_dir}')

# --- the exe -------------------------------------------------------------------------------------------------------
pe = pefile.PE(exe, fast_load=True)
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXCEPTION']])
IB = pe.OPTIONAL_HEADER.ImageBase
image = pe.get_memory_mapped_image()
mem = np.frombuffer(image, dtype=np.uint8)
EXEC = 0x20000000
sections = [(s.VirtualAddress, s.Misc_VirtualSize, bool(s.Characteristics & EXEC)) for s in pe.sections]

entries = sorted((e.struct.BeginAddress, e.struct.EndAddress, e.struct.UnwindData)
                 for e in getattr(pe, 'DIRECTORY_ENTRY_EXCEPTION', []))
starts = [e[0] for e in entries]


def function_start(rva):
    """scan::FunctionStart: the containing entry, chained unwind info followed to the primary entry."""
    i = bisect.bisect_right(starts, rva) - 1
    if i < 0 or not (entries[i][0] <= rva < entries[i][1]):
        return None
    begin, _, info = entries[i]
    for _ in range(16):
        flags = image[info] >> 3
        if not flags & 0x4:
            return begin
        codes = image[info + 2]
        at = info + 4 + ((codes + 1) & ~1) * 2
        begin, _, info = struct.unpack_from('<III', image, at)
    return None


def find_ascii(s):
    needle = s.encode('ascii') + b'\0'
    out = []
    for va, size, ex in sections:
        if ex:
            continue
        blob = image[va:va + size]
        at = blob.find(needle)
        while at != -1:
            if at == 0 or blob[at - 1] == 0:
                out.append(va + at)
            at = blob.find(needle, at + 1)
    return out


CHUNK = 1 << 22


def referencing_functions(target_rva):
    """scan::FunctionsReferencing: every 4-byte window whose rel32 (from its end) lands on the target."""
    found = []
    for va, size, ex in sections:
        if not ex:
            continue
        for c0 in range(0, size, CHUNK):
            n = min(CHUNK, size - c0)
            lo = va + c0
            seg = mem[lo:lo + n + 3].astype(np.int64)
            if len(seg) < 4:
                continue
            disp = seg[:-3] | (seg[1:-2] << 8) | (seg[2:-1] << 16) | (seg[3:] << 24)
            disp = np.where(disp >= 1 << 31, disp - (1 << 32), disp)
            pos = np.arange(lo, lo + len(disp), dtype=np.int64)
            for p in np.nonzero(pos + 4 + disp == target_rva)[0]:
                fn = function_start(int(pos[p]))
                if fn is not None and fn not in found:
                    found.append(fn)
    return found


def prologue_matches(fn, prologue):
    for k, tok in enumerate(prologue.split()):
        if tok.startswith('?'):
            continue
        if image[fn + k] != int(tok, 16):
            return False
    return True


def primary_range(fn):
    """A function's body: its entry plus the contiguous entries chained back to it (a big function's later parts)."""
    i = bisect.bisect_right(starts, fn) - 1
    if i < 0 or entries[i][0] != fn:
        return None
    end = entries[i][1]
    while i + 1 < len(entries) and entries[i + 1][0] == end and function_start(entries[i + 1][0]) == fn:
        i += 1
        end = entries[i][1]
    return fn, end


def reaches(src, dst, depth):
    """scan::Reaches: src calls / jumps to dst within depth levels."""
    r = primary_range(src)
    if not r:
        return False
    callees = []
    for p in range(r[0], r[1] - 4):
        if image[p] not in (0xE8, 0xE9):
            continue
        t = p + 5 + struct.unpack_from('<i', image, p + 1)[0]
        if t == dst:
            return True
        if depth > 1 and primary_range(t) and t not in callees:
            callees.append(t)
    return any(reaches(c, dst, depth - 1) for c in callees)


failed = 0
resolved = {}   # (file, kind) -> [(label, fn)]
for where, label, anchor, prologue, kind in targets:
    strings = find_ascii(anchor.encode().decode('unicode_escape'))
    candidates, refs = [], 0
    for s in strings:
        fns = referencing_functions(s)
        refs += len(fns)
        candidates += [f for f in fns if prologue_matches(f, prologue) and f not in candidates]
    if len(candidates) == 1:
        verdict = f'OK        0x{IB + candidates[0]:X}'
        resolved.setdefault((where.split(':')[0], kind), []).append((label, candidates[0]))
    elif not candidates:
        verdict = 'NOT FOUND'
        failed += 1
    else:
        verdict = 'AMBIGUOUS ' + ' '.join(f'0x{IB + c:X}' for c in candidates)
        failed += 1
    print(f'{verdict:28} {label:34} anchor "{anchor}" ({len(strings)} string(s), {refs} referencing function(s)), '
          f'prologue {prologue}   [{where}]')

print()
chain_failed = 0
for (file, kind), hooks in sorted(resolved.items()):
    roots = resolved.get((file, 'root'), [])
    if kind != 'hook' or len(roots) != 1:
        continue
    root_label, root = roots[0]
    for label, fn in hooks:
        ok = reaches(root, fn, 2)
        chain_failed += not ok
        print(f'{"CONFIRMED" if ok else "ANCHORS DISAGREE":28} {label:34} reached from {root_label} (0x{IB + root:X}) '
              f'within 2 calls   [{file}]')

print(f'\n{len(targets) - failed} of {len(targets)} hook targets resolve uniquely' +
      (f', {chain_failed} cross-check(s) failed' if chain_failed else '') +
      ('' if not failed and not chain_failed else ' - FIX BEFORE RELEASE'))
failed += chain_failed
sys.exit(1 if failed else 0)
