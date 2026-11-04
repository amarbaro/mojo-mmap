"""Memory-mapped files: the whole file as a zero-copy Span, read-only or shared-writable."""
from std.ffi import external_call

comptime NORMAL = 0
comptime RANDOM = 1
comptime SEQUENTIAL = 2
comptime WILLNEED = 3
comptime DONTNEED = 4
comptime _CLOEXEC = 0o2000000
comptime _MAP_FAILED = -1


def _err(what: String, path: String) -> Error:
    """`mmap: <what> <path>: <strerror> (errno N)`, from the current errno."""
    var code = Int(external_call["__errno_location", Pointer[Int32, MutAnyOrigin]]()[])
    var p = external_call["strerror", Pointer[UInt8, MutAnyOrigin]](Int32(code))
    var msg = StringSlice(unsafe_from_utf8=Span(unsafe_ptr=p, length=external_call["strlen", Int](p)))
    return Error("mmap: ", what, " ", path, ": ", msg, " (errno ", code, ")")


def _open(path: String, flags: Int) raises -> Int32:
    var p = path.copy()
    var fd = external_call["open64", Int32](p.as_c_string_span().ptr(), Int32(flags | _CLOEXEC), Int32(0o644))
    if fd < 0:
        raise _err("cannot open", path)
    return fd


struct MappedFile(Movable, Sized):
    """A mapped file. `bytes()` / `mut_bytes()` view the mapping; it is unmapped when the value dies."""

    var base: Int
    var size: Int
    var writable: Bool

    def __init__(out self, path: String, write: Bool = False) raises:
        var fd = _open(path, 2 if write else 0)
        self = Self(_fd=fd, path=path, write=write)

    def __init__(out self, *, _fd: Int32, path: String, write: Bool) raises:
        """Internal: map an open fd (it is closed here, mapped or not)."""
        var fd = _fd
        self.writable = write
        self.base = 0
        self.size = Int(external_call["lseek64", Int64](fd, Int64(0), Int32(2)))
        if self.size < 0:
            var e = _err("cannot size", path)
            _ = external_call["close", Int32](fd)
            raise e^
        if self.size == 0:
            _ = external_call["close", Int32](fd)
            raise Error("mmap: cannot map an empty file: ", path)
        var prot = 3 if write else 1
        self.base = external_call["mmap", Int](Int(0), self.size, Int32(prot), Int32(1), fd, Int64(0))
        if self.base == _MAP_FAILED:
            self.base = 0
            var e = _err("mmap failed", path)  # errno before close()
            _ = external_call["close", Int32](fd)
            raise e^
        _ = external_call["close", Int32](fd)

    def __len__(self) -> Int:
        return self.size

    def bytes(self) -> Span[UInt8, origin_of(self)]:
        """The whole file, no copy."""
        return Span(unsafe_ptr=Pointer[UInt8, origin_of(self)](unsafe_from_address=self.base), length=self.size)

    def mut_bytes(mut self) raises -> Span[UInt8, origin_of(self)]:
        """The whole file, writable; changes reach the file (flush() makes them durable)."""
        if not self.writable:
            raise Error("mmap: mapping is read-only")
        return Span(unsafe_ptr=Pointer[UInt8, origin_of(self)](unsafe_from_address=self.base), length=self.size)

    def advise(self, advice: Int) raises:
        """madvise over the whole mapping: NORMAL, RANDOM, SEQUENTIAL, WILLNEED or DONTNEED."""
        if external_call["madvise", Int32](self.base, self.size, Int32(advice)) != 0:
            raise _err("madvise failed", "")

    def flush(self) raises:
        """msync(MS_SYNC): block until written changes are on disk."""
        if external_call["msync", Int32](self.base, self.size, Int32(4)) != 0:
            raise _err("msync failed", "")

    def __deinit__(deinit self):
        if self.base:
            _ = external_call["munmap", Int32](self.base, self.size)


def create(path: String, size: Int) raises -> MappedFile:
    """Create (or truncate) `path` with `size` zero bytes and map it writable."""
    var fd = _open(path, 2 | 0o100 | 0o1000)
    if external_call["ftruncate64", Int32](fd, Int64(size)) != 0:
        var e = _err("cannot size", path)  # read errno before close() can change it; close exactly once
        _ = external_call["close", Int32](fd)
        raise e^
    return MappedFile(_fd=fd, path=path, write=True)
