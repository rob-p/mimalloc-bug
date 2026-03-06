# macOS mimalloc override MRE

This is a standalone C++17 reproducer for macOS allocator mismatch behavior
under different mimalloc static override link styles and macOS override knobs.

## What it does

- Builds `mimalloc v3.2.8` from source.
- Links a tiny C++ program against `mimalloc-static`.
- Uses static and `thread_local` `std::string` objects across many short-lived
  threads.
- Uses the exact static override recommendation from mimalloc (`mimalloc.o` as
  the first object in the final link line).

## Build + run

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DMI_OVERRIDE=ON -DMI_OSX_ZONE=ON -DMI_OSX_INTERPOSE=ON
cmake --build build -j8
./build/mimalloc_mre
echo $?
```

Expected in the default configured case above: exit code `1` (clean exit).

## Quick matrix

Run:

```bash
./repro.sh
```

Observed on this machine (with `mimalloc.o` first):

- `override=ON zone=ON interpose=ON` -> `1`
- `override=ON zone=ON interpose=OFF` -> `1`
- `override=ON zone=OFF interpose=ON` -> `133`
- `override=ON zone=OFF interpose=OFF` -> `133`
- `override=OFF zone=OFF interpose=OFF` -> `1` (expected program return code)
