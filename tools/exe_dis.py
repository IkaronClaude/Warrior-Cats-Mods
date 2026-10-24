"""Disassemble the unpacked game exe: exe_dis.py <exe> <va or runtime addr> [count] [--base runtime_base]
Runtime addresses (0x7FF6...) are rebased with --base to the file's image base (0x140000000)."""
import sys, pefile, struct
from capstone import Cs, CS_ARCH_X86, CS_MODE_64
exe = sys.argv[1]; addr = int(sys.argv[2], 16); n = int(sys.argv[3]) if len(sys.argv) > 3 and not sys.argv[3].startswith('--') else 60
base_rt = int(sys.argv[sys.argv.index('--base') + 1], 16) if '--base' in sys.argv else None
pe = pefile.PE(exe, fast_load=True); ib = pe.OPTIONAL_HEADER.ImageBase
va = addr - base_rt + ib if base_rt and addr > 0x7F0000000000 else addr
md = Cs(CS_ARCH_X86, CS_MODE_64)
data = pe.get_data(va - ib, n * 15)
for k, ins in enumerate(md.disasm(data, va)):
    if k >= n: break
    print(f'{ins.address:x}  {ins.mnemonic:6} {ins.op_str}')
