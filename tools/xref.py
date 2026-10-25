"""Find code references in the unpacked game exe (for locating native functions to hook).

  xref.py <exe> str <text>           where a UTF-16 / ASCII string lives, and the functions that reference it
  xref.py <exe> addr <va hex>        the functions whose instructions reference a virtual address (RIP-relative)
  xref.py <exe> calls <va hex>       the functions that CALL / JMP a function (E8 / E9 rel32)
  xref.py <exe> func <va hex>        the function (from .pdata) containing an address

Addresses are file virtual addresses (image base 0x140000000), as tools/exe_dis.py prints them. The exe is mapped
once and cached as a numpy array, so each query is a vectorised scan of .text."""
import bisect
import struct
import sys

import numpy as np
import pefile

exe = sys.argv[1]
pe = pefile.PE(exe, fast_load=True)
pe.parse_data_directories(directories=[pefile.DIRECTORY_ENTRY['IMAGE_DIRECTORY_ENTRY_EXCEPTION']])
IB = pe.OPTIONAL_HEADER.ImageBase
image = pe.get_memory_mapped_image()
mem = np.frombuffer(image, dtype=np.uint8)
text = next(s for s in pe.sections if s.Name.rstrip(b'\0') == b'.text')
t0, t1 = text.VirtualAddress, text.VirtualAddress + text.Misc_VirtualSize

funcs = sorted((e.struct.BeginAddress, e.struct.EndAddress) for e in getattr(pe, 'DIRECTORY_ENTRY_EXCEPTION', []))
starts = [f[0] for f in funcs]


def func_of(rva):
    i = bisect.bisect_right(starts, rva) - 1
    if i >= 0 and funcs[i][0] <= rva < funcs[i][1]:
        # chained unwind entries split one function: walk back while the previous entry ends where this begins
        while i > 0 and funcs[i - 1][1] == funcs[i][0]:
            i -= 1
        return funcs[i][0]
    return None


CHUNK = 1 << 22


def rel32_hits(target_rva, extras=(0,)):
    """Offsets o in .text whose int32 at o is a RIP-relative displacement reaching target_rva, i.e.
    o + 4 + extra + int32(o) == target (extra = bytes of immediate after the displacement)."""
    hits = []
    for k in range(4):                       # four aligned int32 views cover every byte offset
        start = t0 + k
        n = (t1 - start) // 4
        view = np.frombuffer(image, dtype='<i4', offset=start, count=n)
        for c in range(0, n, CHUNK):
            d = view[c:c + CHUNK].astype(np.int64)
            pos = start + 4 * (np.arange(c, c + len(d), dtype=np.int64))
            for extra in extras:
                for i in np.nonzero(pos + 4 + extra + d == target_rva)[0]:
                    hits.append((int(pos[i]), extra))
    return hits


def refs_to(target_rva):
    # displacement as the instruction's last field (lea / mov / cmp reg-mem), or followed by an imm8 / imm32
    return sorted({o for o, _ in rel32_hits(target_rva, (0, 1, 4))})


def report(offsets, what):
    byfunc = {}
    for o in offsets:
        byfunc.setdefault(func_of(o), []).append(o)
    print(f'{len(offsets)} {what} in {len(byfunc)} functions')
    for f, os_ in sorted(byfunc.items(), key=lambda kv: kv[0] or 0):
        name = f'{IB + f:X}' if f is not None else '?'
        print(f'  func {name}: ' + ' '.join(f'{IB + o:X}' for o in os_[:8]))


mode = sys.argv[2]
if mode == 'str':
    s = sys.argv[3]
    for enc, pat in (('utf-16', s.encode('utf-16-le') + b'\0\0'), ('ascii', s.encode() + b'\0')):
        pos = image.find(pat)
        while pos != -1:
            print(f'{enc} "{s}" at {IB + pos:X}')
            report(refs_to(pos), 'references')
            pos = image.find(pat, pos + 1)
elif mode == 'addr':
    report(refs_to(int(sys.argv[3], 16) - IB), 'references')
elif mode == 'calls':
    target = int(sys.argv[3], 16) - IB
    hits = [o - 1 for o, _ in rel32_hits(target) if mem[o - 1] in (0xE8, 0xE9)]
    report(sorted(hits), 'calls / jumps')
elif mode == 'ptr':
    # absolute 64-bit pointers to an address anywhere in the image (reflection tables, vtables)
    target = int(sys.argv[3], 16)
    pat = struct.pack('<Q', target)
    pos = image.find(pat)
    n = 0
    while pos != -1 and n < 50:
        sec = next((s.Name.rstrip(b'\0').decode() for s in pe.sections
                    if s.VirtualAddress <= pos < s.VirtualAddress + s.Misc_VirtualSize), '?')
        print(f'pointer at {IB + pos:X} ({sec})')
        pos = image.find(pat, pos + 1)
        n += 1
elif mode == 'func':
    f = func_of(int(sys.argv[3], 16) - IB)
    print(f'{IB + f:X}' if f is not None else 'none')
