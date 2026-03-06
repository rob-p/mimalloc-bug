## Title

macOS arm64 static override behavior depends on exact link mode: `mimalloc.o` first resolves prior crash with `MI_OSX_ZONE=ON`

## Environment

- mimalloc: `v3.2.8`
- OS: `macOS 26.2 (Build 25C56)`
- Kernel: `Darwin 25.2.0 arm64`
- Xcode: `16.2 (16C5032a)`
- Compiler: `Apple clang version 16.0.0 (clang-1600.0.26.6)`
- CMake: `4.2.1`
- CPU/arch: Apple Silicon (`arm64`)

## Summary

Initial crashes were caused by not following the exact static-override link
prescription. After switching to the documented mode (link `mimalloc.o` as the
first object on the final link line), the previous crash with `MI_OSX_ZONE=ON`
does not reproduce.

Error signature:

```text
malloc: *** error for object 0x...: pointer being freed was not allocated
malloc: *** set a breakpoint in malloc_error_break to debug
```

Remaining failing cases are those with `MI_OVERRIDE=ON` and `MI_OSX_ZONE=OFF`.

## Minimal Reproducer

I prepared a standalone repro project (no Salmon dependency):

- `CMakeLists.txt` fetches mimalloc `v3.2.8`
- C++ app uses static + `thread_local std::string` objects and many short-lived threads

Key source files:

- `main.cpp`
- `plugin.cpp`

Build/run command (failing case):

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DMI_OVERRIDE=ON -DMI_OSX_ZONE=ON -DMI_OSX_INTERPOSE=ON
cmake --build build -j8
./build/mimalloc_mre
```

Observed exit code on this machine: `133`.

## Matrix (same MRE, with `mimalloc.o` first)

- `MI_OVERRIDE=ON MI_OSX_ZONE=ON MI_OSX_INTERPOSE=ON` -> stable (`1`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=ON MI_OSX_INTERPOSE=OFF` -> stable (`1`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=ON` -> crash (`133`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=OFF` -> crash (`133`)
- `MI_OVERRIDE=OFF MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=OFF` -> stable (`1`)

## Also tested on `dev3`

I also tested current `dev3` head:

- `b88ce9c8fd6b7c9208a43bcdb705de9f499dbad4` (`refs/heads/dev3` at test time)

Result is unchanged for this corrected link mode:

- `MI_OSX_ZONE=ON` cases are stable
- `MI_OSX_ZONE=OFF` cases fail

## LLDB backtrace excerpt (failing `MI_OSX_ZONE=OFF` case)

```text
thread #N:
  libsystem_malloc.dylib`___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED
  libsystem_pthread.dylib`_pthread_tsd_cleanup
  libsystem_pthread.dylib`_pthread_exit
```

Main thread is typically waiting in `std::thread::join()`.

## Notes

- This closely resembles the thread/TLS cleanup path discussed in issue #1029.
- The original “all override modes fail” observation was from linking
  `libmimalloc.a` in the normal library list, not `mimalloc.o` first.
