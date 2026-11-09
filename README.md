# mojo-mmap

<!-- badges -->
[![ci](https://github.com/amarbaro/mojo-mmap/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/amarbaro/mojo-mmap/actions/workflows/ci.yml) [![latest release](https://img.shields.io/github/v/release/amarbaro/mojo-mmap)](https://github.com/amarbaro/mojo-mmap/releases/latest) [![license](https://img.shields.io/github/license/amarbaro/mojo-mmap)](https://github.com/amarbaro/mojo-mmap/blob/main/LICENSE) [![checks](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/amarbaro/mojo-mmap/badges/checks.json)](https://github.com/amarbaro/mojo-mmap/actions/workflows/ci.yml)
<!-- /badges -->

Memory-mapped files for Mojo. A file becomes one zero-copy `Span[UInt8]`, read-only or shared and writable, with `madvise` and `msync`. 71 lines of code (`mojo-loc`), Linux, no dependencies beyond libc.

Install: `pixi workspace channel add https://conda.modular.com/max https://prefix.dev/amarbaro/amarbaro`, then `pixi add mojo-mmap` (import `mmap`). From source: `git clone https://github.com/amarbaro/mojo-mmap`, then `mojo run -I mojo-mmap/src app.mojo`.
Toolchains: Mojo 1.2 stable, and the nightly 1.3.0.dev2026110805 in the weekly [mojo-libs](https://github.com/amarbaro/mojo-libs) matrix (36 libraries on stable, 35 on nightly).

```mojo
from mmap import MappedFile, create, SEQUENTIAL


def main() raises:
    var w = create("data.bin", 1 << 20)      # sized, zero-filled, writable
    var b = w.mut_bytes()
    b[0] = 42
    w.flush()                                # msync: durable on disk

    var m = MappedFile("data.bin")           # read-only
    m.advise(SEQUENTIAL)
    print(len(m), m.bytes()[0])              # no copy, no read()
```

| Call | Does |
|---|---|
| `MappedFile(path, write=False)` | Maps the whole file. `write=True` maps it shared and writable. Raises on a missing or empty file (as Python `mmap` does for empty files). |
| `len(m)` | File size in bytes, fixed at map time. |
| `m.bytes() -> Span[UInt8]` | The mapping, no copy. Valid while `m` lives. |
| `m.mut_bytes() -> Span[UInt8]` | Writable view; raises on a read-only mapping. Writes reach the file. |
| `m.advise(advice)` | `madvise` over the whole mapping. |
| `m.flush()` | `msync(MS_SYNC)`: blocks until written pages are on disk. |
| `create(path, size) -> MappedFile` | Creates or truncates `path` to `size` zero bytes, mapped writable. |

**Checked against Python `mmap`:** reads, writes and in-place updates over 1 B to 1 MiB (page edges included), and the empty-file and missing-file errors, each scenario twice (`scripts/check.sh`). 3 of 3 mutants caught (`scripts/mutants.sh`). Builds and passes on Mojo 1.2.0 and the 1.3 nightly.

**Speed** (256 MiB file, warm page cache, 7800X3D): 24.9 GB/s summing through the mapping, against 1.2 GB/s for `read_bytes()` into a buffer (`tests/bench.mojo`).

**Requires** Mojo 1.2 on Linux (x86-64 or aarch64 glibc).

- API: [docs/api.md](docs/api.md) · design: [docs/design.md](docs/design.md) · agent skill: [skills/mojo-mmap/SKILL.md](skills/mojo-mmap/SKILL.md)
- License: Apache-2.0
