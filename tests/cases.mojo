# The Mojo side of tools/oracle.py: `cases SCENARIO DIR` prints the same lines.
from std.sys import argv
from mmap import MappedFile, create, SEQUENTIAL


def pattern(n: Int) -> List[UInt8]:
    var b = List[UInt8](capacity=n)
    for i in range(n):
        b.append(UInt8((i * 31 + 7) & 255))
    return b^


def hex16(b: Span[UInt8, _]) -> String:
    comptime H = "0123456789abcdef"
    var s = String()
    for i in range(len(b)):
        s += H[byte=Int(b[i] >> 4)]
        s += H[byte=Int(b[i] & 15)]
    return s


def digest(b: Span[UInt8, _]) -> String:
    var t: UInt64 = 0
    for i in range(len(b)):
        t += UInt64(b[i])
    var n = len(b)
    return String(n, " ", t & 0xFFFFFFFF, " ", hex16(b[: min(16, n)]), " ", hex16(b[max(0, n - 16) :]))


def write_file(p: String, data: Span[UInt8, _]) raises:
    with open(p, "w") as f:
        f.write_bytes(data)


def read_file(p: String) raises -> List[UInt8]:
    with open(p, "r") as f:
        return f.read_bytes()


comptime SIZES: List[Int] = [1, 4095, 4096, 4097, 65536, 1 << 20]


def main() raises:
    var c = argv()[1]
    var d = String(argv()[2])
    if c == "read":
        for n in materialize[SIZES]():
            var p = d + "/r" + String(n)
            write_file(p, pattern(n))
            var m = MappedFile(p)
            m.advise(SEQUENTIAL)
            print("read", digest(m.bytes()))
    elif c == "write":
        for n in materialize[SIZES]():
            var p = d + "/w" + String(n)
            var m = create(p, n)
            var b = m.mut_bytes()
            for i in range(0, n, 7):
                b[i] = UInt8((i * 13) & 255)
            m.flush()
            print("write", digest(read_file(p)))
    elif c == "update":
        var p = d + "/u"
        write_file(p, pattern(10000))
        var m = MappedFile(p, write=True)
        var b = m.mut_bytes()
        var s = "0123456789".as_bytes()
        for i in range(10):
            b[100 + i] = s[i]
        m.flush()
        _ = m^
        print("update", digest(read_file(p)))
    elif c == "errors":
        write_file(d + "/empty", List[UInt8]())
        for p in [d + "/empty", d + "/missing"]:
            try:
                _ = MappedFile(p)
                print("error none")
            except e:
                print("error empty" if "empty" in String(e) else "error open")
