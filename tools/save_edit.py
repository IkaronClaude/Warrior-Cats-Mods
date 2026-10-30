"""Edit the JSON inside the game's save (%LOCALAPPDATA%/Wrc/Saved/SaveGames/WrcGame.sav) - e.g. undo a test's rename.

  save_edit.py <in.sav> <out.sav> <old text> <new text>   (old text must occur exactly once; writes out.sav + out.sav.json)

Format: the USwtSaveGame property CompressedData (a byte array) = UE5 chunked zlib (tag C1832A9E22222222, 128 KiB
chunks, compressor byte 3) of [u32 n+8][u32 n][the save's JSON, each byte minus 1][u32 n]; WrcGame.json is the same
JSON in the clear. The save's Hash property is NOT checked on load (VM 2026-10-30: an edited save with the old hash
loaded, and the game's next save kept the edit). Quit the game first, back up, copy both files over the originals."""
import sys, zlib, struct
TAG = bytes.fromhex('c1832a9e22222222')
CHUNK = 131072

def decode(d):
    start = d.find(TAG)
    cnt = struct.unpack_from('<I', d, start - 4)[0]
    p, out = start, b''
    while p < start + cnt:
        csz, comp, sc, su = struct.unpack_from('<QBQQ', d, p + 8); p += 33
        n = (su + csz - 1) // csz
        sizes = [struct.unpack_from('<QQ', d, p + 16 * k) for k in range(n)]; p += 16 * n
        for c, u in sizes:
            out += zlib.decompress(d[p:p + c]); p += c
    n = struct.unpack_from('<I', out, 4)[0]
    js = bytes((b + 1) & 255 for b in out[8:8 + n])
    return start, cnt, js

def encode(js):
    n = len(js)
    raw = struct.pack('<II', n + 8, n) + bytes((b - 1) & 255 for b in js) + struct.pack('<I', n)
    blob = b''
    for i in range(0, len(raw), CHUNK):
        part = raw[i:i + CHUNK]; z = zlib.compress(part, 1)
        blob += TAG + struct.pack('<QBQQ', CHUNK, 3, len(z), len(part)) + struct.pack('<QQ', len(z), len(part)) + z
    return blob

def rewrite(d, js):
    start, cnt, _ = decode(d)
    blob = encode(js)
    head = bytearray(d[:start])
    struct.pack_into('<I', head, start - 4, len(blob))
    k = bytes(head[start - 16:start - 4]).rfind(struct.pack('<I', cnt + 4))
    assert k >= 0, 'property size not found'
    struct.pack_into('<I', head, start - 16 + k, len(blob) + 4)
    return bytes(head) + blob + d[start + cnt:]

if __name__ == '__main__':
    src, dst, old, new = sys.argv[1:5]
    d = open(src, 'rb').read()
    _, _, js = decode(d)
    oldb, newb = old.encode(), new.encode()
    assert js.count(oldb) == 1, js.count(oldb)
    js2 = js.replace(oldb, newb)
    out = rewrite(d, js2)
    assert decode(out)[2] == js2
    open(dst, 'wb').write(out)
    open(dst + '.json', 'wb').write(js2)
    print('ok', len(d), '->', len(out))
