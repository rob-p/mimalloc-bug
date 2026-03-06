## Title

macOS arm64: deterministic `pointer being freed was not allocated` with `MI_OVERRIDE=ON` (v3.2.8), reproducible in standalone C++ MRE

## Environment

- mimalloc: `v3.2.8`
- OS: `macOS 26.2 (Build 25C56)`
- Kernel: `Darwin 25.2.0 arm64`
- Xcode: `16.2 (16C5032a)`
- Compiler: `Apple clang version 16.0.0 (clang-1600.0.26.6)`
- CMake: `4.2.1`
- CPU/arch: Apple Silicon (`arm64`)

## Summary

I can reproduce a deterministic crash in a minimal standalone C++ program when
mimalloc is built and linked in override mode on macOS.

Error signature:

```text
malloc: *** error for object 0x...: pointer being freed was not allocated
malloc: *** set a breakpoint in malloc_error_break to debug
```

The same MRE is stable when `MI_OVERRIDE=OFF`.

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

## Matrix (same MRE)

- `MI_OVERRIDE=ON MI_OSX_ZONE=ON MI_OSX_INTERPOSE=ON` -> crash (`133`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=ON MI_OSX_INTERPOSE=OFF` -> crash (`133`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=ON` -> crash (`133`)
- `MI_OVERRIDE=ON MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=OFF` -> crash (`133`)
- `MI_OVERRIDE=OFF MI_OSX_ZONE=OFF MI_OSX_INTERPOSE=OFF` -> stable (`1`, expected app return code)

## Also tested on `dev3`

I also tested current `dev3` head:

- `b88ce9c8fd6b7c9208a43bcdb705de9f499dbad4` (`refs/heads/dev3` at test time)

Result is unchanged for this MRE:

- all `MI_OVERRIDE=ON` combinations above still fail (`133`)
- `MI_OVERRIDE=OFF` remains stable

## LLDB backtrace excerpt

```text
thread #N:
  libsystem_malloc.dylib`___BUG_IN_CLIENT_OF_LIBMALLOC_POINTER_BEING_FREED_WAS_NOT_ALLOCATED
  libsystem_pthread.dylib`_pthread_tsd_cleanup
  libsystem_pthread.dylib`_pthread_exit
```

Main thread is typically waiting in `std::thread::join()`.

## Notes

- This resembles the thread/TLS cleanup pattern discussed in issue #1029.
- I can share the complete MRE directory and full LLDB trace if needed.
