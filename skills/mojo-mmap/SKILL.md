---
name: mojo-mmap
description: "Map a file into memory from Mojo with mojo-mmap: zero-copy Span views, writable mappings, madvise, msync. Use when a Mojo program reads large files (weights, datasets, indexes) or writes a fixed-size file in place."
---

# mojo-mmap

```mojo
from mmap import MappedFile, create, SEQUENTIAL, WILLNEED
var m = MappedFile(path)            # read-only, whole file
m.advise(WILLNEED)                  # prefetch before a hot loop
var b = m.bytes()                   # Span[UInt8], no copy
var w = create(out_path, n)         # writable, zero-filled, n bytes
w.mut_bytes()[0] = 1; w.flush()
```

Gotchas:
- A `Span` from `bytes()` is valid only while the `MappedFile` lives; keep the struct in scope (Mojo destroys values at their last use).
- Empty files raise. Check the size first if empty is normal for you.
- The size is fixed at map time. If another process truncates the file, touching the lost tail raises SIGBUS (as in C and Python): do not map files others shrink.
- `flush()` is needed for durability, not for visibility: other processes see writes immediately.

Gate: `scripts/ci.sh` (Python `mmap` oracle, mutants, api, quickstart).
