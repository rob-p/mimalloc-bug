#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRA_CMAKE_ARGS=("$@")
BUILD_PREFIX="${BUILD_PREFIX:-}"

build_and_run() {
  local override="$1"
  local zone="$2"
  local interpose="$3"
  local bdir="${ROOT}/${BUILD_PREFIX}build-o${override}-z${zone}-i${interpose}"

  local cmake_args=(
    -S "${ROOT}"
    -B "${bdir}"
    -DCMAKE_BUILD_TYPE=Release
    -DMI_OVERRIDE="${override}"
    -DMI_OSX_ZONE="${zone}"
    -DMI_OSX_INTERPOSE="${interpose}"
  )
  if ((${#EXTRA_CMAKE_ARGS[@]} > 0)); then
    cmake_args+=("${EXTRA_CMAKE_ARGS[@]}")
  fi
  cmake "${cmake_args[@]}" >/dev/null

  cmake --build "${bdir}" -j8 >/dev/null
  "${bdir}/mimalloc_mre" >/dev/null 2>&1
  echo "$?"
}

echo "override=ON zone=ON interpose=ON exit=$(build_and_run ON ON ON)"
echo "override=ON zone=ON interpose=OFF exit=$(build_and_run ON ON OFF)"
echo "override=ON zone=OFF interpose=ON exit=$(build_and_run ON OFF ON)"
echo "override=ON zone=OFF interpose=OFF exit=$(build_and_run ON OFF OFF)"
echo "override=OFF zone=OFF interpose=OFF exit=$(build_and_run OFF OFF OFF)"
