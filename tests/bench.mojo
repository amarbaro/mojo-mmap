# Throughput: sum a 256 MiB file through the mapping vs read() into a buffer. Page cache warm.
from std.time import perf_counter_ns
from mmap import MappedFile, create, SEQUENTIAL


def sum_span(b: Span[UInt8, _]) -> UInt64:
    var t: UInt64 = 0
    var p = b.unsafe_ptr()
    var n = len(b)
    var i = 0
    var acc = SIMD[DType.uint64, 8](0)
    while i + 64 <= n:
        acc += (p + i).load[width=64]().cast[DType.uint16]().reduce_add[8]().cast[DType.uint64]()
        i += 64
    t = acc.reduce_add()
    while i < n:
        t += UInt64(p[i])
        i += 1
    return t


def main() raises:
    comptime N = 256 << 20
    var p = ".work/bench.bin"
    var w = create(p, N)
    var b = w.mut_bytes()
    for i in range(N):
        b[i] = UInt8(i & 255)
    w.flush()
    _ = w^
    var best_m = Int.MAX
    var best_r = Int.MAX
    var s1: UInt64 = 0
    var s2: UInt64 = 0
    for _ in range(5):
        var t0 = perf_counter_ns()
        var m = MappedFile(p)
        m.advise(SEQUENTIAL)
        s1 = sum_span(m.bytes())
        _ = m^
        best_m = min(best_m, Int(perf_counter_ns() - t0))
        t0 = perf_counter_ns()
        with open(p, "r") as f:
            var data = f.read_bytes()
            s2 = sum_span(data)
        best_r = min(best_r, Int(perf_counter_ns() - t0))
    if s1 != s2:
        raise Error("FAIL bench: sums differ")
    print("mmap  GB/s", Float64(N) / Float64(best_m))
    print("read  GB/s", Float64(N) / Float64(best_r))
    print("ratio mmap/read", Float64(best_r) / Float64(best_m))
