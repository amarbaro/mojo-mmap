# Every public call once, plus the README example.
from std.os import remove
from mmap import MappedFile, create, NORMAL, RANDOM, SEQUENTIAL, WILLNEED, DONTNEED


def check(ok: Bool, what: String) raises:
    if not ok:
        raise Error("FAIL api: " + what)


def main() raises:
    var p = ".work/api.bin"
    var w = create(p, 4096)
    check(len(w) == 4096, "create size")
    var b = w.mut_bytes()
    b[0] = 42
    b[4095] = 7
    w.flush()
    for a in [NORMAL, RANDOM, SEQUENTIAL, WILLNEED, DONTNEED]:
        w.advise(a)
    _ = w^
    var r = MappedFile(p)
    check(r.bytes()[0] == 42 and r.bytes()[4095] == 7, "read back")
    var raised = False
    try:
        _ = r.mut_bytes()
    except:
        raised = True
    check(raised, "read-only mapping refuses mut_bytes")
    remove(p)
    print("PASS api")
