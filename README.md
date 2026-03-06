# macOS mimalloc override MRE

This is a standalone C++17 reproducer for a macOS allocator mismatch crash when
`mimalloc` is used in override mode.

## What it does

- Builds `mimalloc v3.2.8` from source.
- Links a tiny C++ program against `mimalloc-static`.
- Uses static and `thread_local` `std::string` objects across many short-lived
  threads.
- Reproduces `pointer being freed was not allocated` in `libsystem_malloc` when
  `MI_OVERRIDE=ON`.

## Build + run

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DMI_OVERRIDE=ON -DMI_OSX_ZONE=ON -DMI_OSX_INTERPOSE=ON
cmake --build build -j8
./build/mimalloc_mre
echo $?
```

Expected on the affected system: exit code `133`.

## Quick matrix

Run:

```bash
./repro.sh
```

Observed on this machine:

- `override=ON zone=ON interpose=ON` -> `133`
- `override=ON zone=ON interpose=OFF` -> `133`
- `override=ON zone=OFF interpose=ON` -> `133`
- `override=ON zone=OFF interpose=OFF` -> `133`
- `override=OFF zone=OFF interpose=OFF` -> `1` (expected program return code)
