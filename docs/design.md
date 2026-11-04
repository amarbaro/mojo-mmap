# Design

- **One struct, three fields** (`base`, `size`, `writable`: 24 bytes). No fd kept: Linux keeps the mapping valid after `close`, so nothing leaks if the value is moved around.
- **Views, never copies.** `bytes()` returns a `Span` tied to the `MappedFile`'s origin, so the borrow checker stops a view from outliving the mapping.
- **Shared mapping for both modes.** Read-only maps `PROT_READ` + `MAP_SHARED`; writable adds `PROT_WRITE`. Private copy-on-write mappings are not offered: nobody asked, and they hide writes from other readers.
- **Empty files raise**, matching Python `mmap`; Linux refuses a zero-length mapping anyway.
- **No resize.** `mremap` is Linux-only and rarely needed; re-create the mapping instead.
- Syscalls through `external_call` (`open64`, `lseek64`, `ftruncate64`, `mmap`, `madvise`, `msync`, `munmap`); the same calls mojo-gguf-core uses for its reader.
