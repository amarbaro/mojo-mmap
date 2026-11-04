# API

`from mmap import MappedFile, create, NORMAL, RANDOM, SEQUENTIAL, WILLNEED, DONTNEED`

| Call | Does |
|---|---|
| `MappedFile(path, write=False)` | Maps the whole file. `write=True` maps it shared and writable. Raises on a missing or empty file (as Python `mmap` does for empty files). |
| `len(m)` | File size in bytes, fixed at map time. |
| `m.bytes() -> Span[UInt8]` | The mapping, no copy. Valid while `m` lives. |
| `m.mut_bytes() -> Span[UInt8]` | Writable view; raises on a read-only mapping. Writes reach the file. |
| `m.advise(advice)` | `madvise` over the whole mapping. |
| `m.flush()` | `msync(MS_SYNC)`: blocks until written pages are on disk. |
| `create(path, size) -> MappedFile` | Creates or truncates `path` to `size` zero bytes, mapped writable. |

The mapping is unmapped when the value is destroyed. The file descriptor is closed right after mapping, so a `MappedFile` holds no fd.

Errors read `mmap: <what> <path>: <strerror> (errno N)`, so a missing file and a permission problem are told apart.
