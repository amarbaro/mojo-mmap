"""Oracle: Python mmap. `oracle.py --list` names the scenarios; `oracle.py NAME DIR` prints its lines."""
import mmap, os, sys

def pattern(n): return bytes((i * 31 + 7) & 255 for i in range(n))
def digest(b): return f"{len(b)} {sum(b) & 0xFFFFFFFF} {b[:16].hex()} {b[-16:].hex()}"
SIZES = [1, 4095, 4096, 4097, 65536, 1 << 20]

def read(d):
    for n in SIZES:
        p = f"{d}/r{n}"; open(p, "wb").write(pattern(n))
        with open(p, "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
            m.madvise(mmap.MADV_SEQUENTIAL); print("read", digest(m[:]))

def write(d):
    for n in SIZES:
        p = f"{d}/w{n}"
        with open(p, "w+b") as f:
            f.truncate(n)
            with mmap.mmap(f.fileno(), n) as m:
                for i in range(0, n, 7): m[i] = (i * 13) & 255
                m.flush()
        print("write", digest(open(p, "rb").read()))

def update(d):
    p = f"{d}/u"; open(p, "wb").write(pattern(10000))
    with open(p, "r+b") as f, mmap.mmap(f.fileno(), 0) as m:
        m[100:110] = b"0123456789"; m.flush()
    print("update", digest(open(p, "rb").read()))

def errors(d):
    open(f"{d}/empty", "wb").close()
    for p in (f"{d}/empty", f"{d}/missing"):
        try:
            with open(p, "rb") as f: mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ)
            print("error none")
        except ValueError: print("error empty")
        except OSError: print("error open")

S = {"read": read, "write": write, "update": update, "errors": errors}
if sys.argv[1] == "--list": print("\n".join(S))
else: S[sys.argv[1]](sys.argv[2])
