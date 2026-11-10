"""Same work as tests/bench.mojo in Python: sum the 256 MiB file through mmap and through read(), numpy for the sum, best of 5.
Run after tests/bench.mojo, which writes .work/bench.bin."""
import mmap, time
import numpy as np
p, N = ".work/bench.bin", 256 << 20
bm = br = 1 << 62
for _ in range(5):
    t0 = time.perf_counter_ns()
    with open(p, "rb") as f, mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as m:
        m.madvise(mmap.MADV_SEQUENTIAL); s1 = int(np.frombuffer(m, dtype=np.uint8).sum(dtype=np.uint64))
    bm = min(bm, time.perf_counter_ns() - t0); t0 = time.perf_counter_ns()
    with open(p, "rb") as f: s2 = int(np.frombuffer(f.read(), dtype=np.uint8).sum(dtype=np.uint64))
    br = min(br, time.perf_counter_ns() - t0)
assert s1 == s2, "FAIL bench: sums differ"
print("mmap  GB/s", N / bm, "; read  GB/s", N / br, "; check", s1)
