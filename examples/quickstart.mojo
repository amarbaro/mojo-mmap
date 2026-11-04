# Write a file through a mapping, then read it back with no copy.
from std.os import getenv, remove
from std.ffi import external_call
from mmap import MappedFile, create, SEQUENTIAL


def main() raises:
    var path = getenv("TMPDIR", "/tmp") + "/mojo-mmap-quickstart-" + String(Int(external_call["getpid", Int32]())) + ".bin"
    var w = create(path, 1 << 20)
    var b = w.mut_bytes()
    for i in range(len(b)):
        b[i] = UInt8(i & 255)
    w.flush()
    _ = w^

    var m = MappedFile(path)
    m.advise(SEQUENTIAL)
    var total = 0
    for v in m.bytes():
        total += Int(v)
    print(len(m), "bytes, sum", total)
    remove(path)
