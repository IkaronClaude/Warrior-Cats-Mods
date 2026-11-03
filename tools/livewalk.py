"""Live, unwind-correct stack of one thread of a running (hung) process: dbghelp StackWalk64 + symbols.
usage: python livewalk.py <pid> <tid> [symbol path]"""
import ctypes, ctypes.wintypes as w, os, sys

KITS = r'C:\Program Files (x86)\Windows Kits\10\Debuggers\x64'
os.add_dll_directory(KITS)
dbg = ctypes.WinDLL(os.path.join(KITS, 'dbghelp.dll'), use_last_error=True)
k32 = ctypes.WinDLL('kernel32', use_last_error=True)

pid, tid = int(sys.argv[1]), int(sys.argv[2])
sympath = sys.argv[3] if len(sys.argv) > 3 else None

k32.OpenProcess.restype = ctypes.c_void_p
k32.OpenThread.restype = ctypes.c_void_p
hp = k32.OpenProcess(0x1F0FFF, False, pid)
ht = k32.OpenThread(0x1F03FF, False, tid)
assert hp and ht, ctypes.get_last_error()

dbg.SymSetOptions(0x2 | 0x10 | 0x4)          # undname, load lines, deferred
dbg.SymInitializeW.argtypes = [ctypes.c_void_p, ctypes.c_wchar_p, w.BOOL]
assert dbg.SymInitializeW(ctypes.c_void_p(hp), sympath, True), ctypes.get_last_error()

# CONTEXT (AMD64), 16-byte aligned
class M128(ctypes.Structure):
    _fields_ = [('lo', ctypes.c_uint64), ('hi', ctypes.c_uint64)]
class CONTEXT(ctypes.Structure):
    _pack_ = 16
    _fields_ = [('P1Home', ctypes.c_uint64), ('P2Home', ctypes.c_uint64), ('P3Home', ctypes.c_uint64),
                ('P4Home', ctypes.c_uint64), ('P5Home', ctypes.c_uint64), ('P6Home', ctypes.c_uint64),
                ('ContextFlags', w.DWORD), ('MxCsr', w.DWORD),
                ('SegCs', w.WORD), ('SegDs', w.WORD), ('SegEs', w.WORD), ('SegFs', w.WORD), ('SegGs', w.WORD),
                ('SegSs', w.WORD), ('EFlags', w.DWORD),
                ('Dr0', ctypes.c_uint64), ('Dr1', ctypes.c_uint64), ('Dr2', ctypes.c_uint64), ('Dr3', ctypes.c_uint64),
                ('Dr6', ctypes.c_uint64), ('Dr7', ctypes.c_uint64),
                ('Rax', ctypes.c_uint64), ('Rcx', ctypes.c_uint64), ('Rdx', ctypes.c_uint64), ('Rbx', ctypes.c_uint64),
                ('Rsp', ctypes.c_uint64), ('Rbp', ctypes.c_uint64), ('Rsi', ctypes.c_uint64), ('Rdi', ctypes.c_uint64),
                ('R8', ctypes.c_uint64), ('R9', ctypes.c_uint64), ('R10', ctypes.c_uint64), ('R11', ctypes.c_uint64),
                ('R12', ctypes.c_uint64), ('R13', ctypes.c_uint64), ('R14', ctypes.c_uint64), ('R15', ctypes.c_uint64),
                ('Rip', ctypes.c_uint64),
                ('FltSave', ctypes.c_byte * 512),
                ('VectorRegister', M128 * 26), ('VectorControl', ctypes.c_uint64),
                ('DebugControl', ctypes.c_uint64), ('LastBranchToRip', ctypes.c_uint64),
                ('LastBranchFromRip', ctypes.c_uint64), ('LastExceptionToRip', ctypes.c_uint64),
                ('LastExceptionFromRip', ctypes.c_uint64)]
buf = ctypes.create_string_buffer(ctypes.sizeof(CONTEXT) + 16)
addr = (ctypes.addressof(buf) + 15) & ~15
ctx = CONTEXT.from_address(addr)
ctx.ContextFlags = 0x10000B                   # CONTEXT_FULL (AMD64)
k32.SuspendThread(ctypes.c_void_p(ht))
assert k32.GetThreadContext(ctypes.c_void_p(ht), ctypes.byref(ctx)), ctypes.get_last_error()
print(f'rip {ctx.Rip:#x} rsp {ctx.Rsp:#x} rcx {ctx.Rcx:#x} rdx {ctx.Rdx:#x} rbx {ctx.Rbx:#x} rsi {ctx.Rsi:#x} rdi {ctx.Rdi:#x}')

class ADDRESS64(ctypes.Structure):
    _fields_ = [('Offset', ctypes.c_uint64), ('Segment', w.WORD), ('Mode', ctypes.c_int)]
class KDHELP64(ctypes.Structure):
    _fields_ = [('data', ctypes.c_uint64 * 22)]
class STACKFRAME64(ctypes.Structure):
    _fields_ = [('AddrPC', ADDRESS64), ('AddrReturn', ADDRESS64), ('AddrFrame', ADDRESS64), ('AddrStack', ADDRESS64),
                ('AddrBStore', ADDRESS64), ('FuncTableEntry', ctypes.c_void_p), ('Params', ctypes.c_uint64 * 4),
                ('Far', w.BOOL), ('Virtual', w.BOOL), ('Reserved', ctypes.c_uint64 * 3), ('KdHelp', KDHELP64)]
sf = STACKFRAME64()
sf.AddrPC.Offset, sf.AddrPC.Mode = ctx.Rip, 3
sf.AddrFrame.Offset, sf.AddrFrame.Mode = ctx.Rsp, 3
sf.AddrStack.Offset, sf.AddrStack.Mode = ctx.Rsp, 3

class SYM(ctypes.Structure):
    _fields_ = [('SizeOfStruct', w.ULONG), ('TypeIndex', w.ULONG), ('Reserved', ctypes.c_uint64 * 2), ('Index', w.ULONG),
                ('Size', w.ULONG), ('ModBase', ctypes.c_uint64), ('Flags', w.ULONG), ('Value', ctypes.c_uint64),
                ('Address', ctypes.c_uint64), ('Register', w.ULONG), ('Scope', w.ULONG), ('Tag', w.ULONG),
                ('NameLen', w.ULONG), ('MaxNameLen', w.ULONG), ('Name', ctypes.c_wchar * 1024)]
class MODINFO(ctypes.Structure):
    _fields_ = [('SizeOfStruct', w.DWORD), ('BaseOfImage', ctypes.c_uint64), ('ImageSize', w.DWORD),
                ('TimeDateStamp', w.DWORD), ('CheckSum', w.DWORD), ('NumSyms', w.DWORD), ('SymType', w.DWORD),
                ('ModuleName', ctypes.c_wchar * 32), ('ImageName', ctypes.c_wchar * 256), ('LoadedImageName', ctypes.c_wchar * 256),
                ('LoadedPdbName', ctypes.c_wchar * 256), ('CVSig', w.DWORD), ('CVData', ctypes.c_wchar * 780),
                ('PdbSig', w.DWORD), ('PdbSig70', ctypes.c_byte * 16), ('PdbAge', w.DWORD), ('PdbUnmatched', w.BOOL),
                ('DbgUnmatched', w.BOOL), ('LineNumbers', w.BOOL), ('GlobalSymbols', w.BOOL), ('TypeInfo', w.BOOL),
                ('SourceIndexed', w.BOOL), ('Publics', w.BOOL), ('MachineType', w.DWORD), ('Reserved', w.DWORD)]

FTA = ctypes.WINFUNCTYPE(ctypes.c_void_p, ctypes.c_void_p, ctypes.c_uint64)
GMB = ctypes.WINFUNCTYPE(ctypes.c_uint64, ctypes.c_void_p, ctypes.c_uint64)
fta = ctypes.cast(dbg.SymFunctionTableAccess64, ctypes.c_void_p).value
gmb = ctypes.cast(dbg.SymGetModuleBase64, ctypes.c_void_p).value
dbg.StackWalk64.argtypes = [w.DWORD, ctypes.c_void_p, ctypes.c_void_p, ctypes.POINTER(STACKFRAME64), ctypes.c_void_p,
                            ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p, ctypes.c_void_p]
dbg.SymFromAddrW.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.POINTER(ctypes.c_uint64), ctypes.POINTER(SYM)]
dbg.SymGetModuleInfoW64.argtypes = [ctypes.c_void_p, ctypes.c_uint64, ctypes.POINTER(MODINFO)]

for n in range(60):
    if not dbg.StackWalk64(0x8664, ctypes.c_void_p(hp), ctypes.c_void_p(ht), ctypes.byref(sf), ctypes.c_void_p(addr),
                           None, ctypes.c_void_p(fta), ctypes.c_void_p(gmb), None):
        break
    pc = sf.AddrPC.Offset
    if not pc:
        break
    s = SYM(); s.SizeOfStruct = 88; s.MaxNameLen = 1023
    disp = ctypes.c_uint64()
    mi = MODINFO(); mi.SizeOfStruct = ctypes.sizeof(MODINFO)
    mod = mi.ModuleName if dbg.SymGetModuleInfoW64(ctypes.c_void_p(hp), pc, ctypes.byref(mi)) else '?'
    name = (s.Name + f'+{disp.value:#x}') if dbg.SymFromAddrW(ctypes.c_void_p(hp), pc, ctypes.byref(disp), ctypes.byref(s)) else '?'
    print(f'{n:2} {pc:#018x} sp {sf.AddrStack.Offset:#x} {mod}!{name}  p={sf.Params[0]:#x},{sf.Params[1]:#x}')

k32.ResumeThread(ctypes.c_void_p(ht))
