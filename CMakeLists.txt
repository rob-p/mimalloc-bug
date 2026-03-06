cmake_minimum_required(VERSION 3.24)
project(mimalloc_macos_mre LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include(FetchContent)

set(MIMALLOC_VERSION "v3.2.8" CACHE STRING "mimalloc tag to fetch when not using GIT_TAG")
set(MIMALLOC_GIT_TAG "" CACHE STRING "Optional mimalloc git tag/branch/SHA to fetch directly")

if(NOT DEFINED MI_OVERRIDE)
  set(MI_OVERRIDE ON CACHE BOOL "" FORCE)
endif()
if(NOT DEFINED MI_OSX_ZONE)
  set(MI_OSX_ZONE ON CACHE BOOL "" FORCE)
endif()
if(NOT DEFINED MI_OSX_INTERPOSE)
  set(MI_OSX_INTERPOSE ON CACHE BOOL "" FORCE)
endif()
if(NOT DEFINED MI_TRACK_ASAN)
  set(MI_TRACK_ASAN OFF CACHE BOOL "" FORCE)
endif()

if(MIMALLOC_GIT_TAG)
  FetchContent_Declare(
    mimalloc_src
    GIT_REPOSITORY https://github.com/microsoft/mimalloc.git
    GIT_TAG ${MIMALLOC_GIT_TAG}
    GIT_SHALLOW TRUE
  )
else()
  if(NOT MIMALLOC_VERSION STREQUAL "v3.2.8")
    message(FATAL_ERROR "Only v3.2.8 tarball hash is pinned; use MIMALLOC_GIT_TAG for other revisions")
  endif()
  FetchContent_Declare(
    mimalloc_src
    URL https://github.com/microsoft/mimalloc/archive/refs/tags/v3.2.8.tar.gz
    URL_HASH SHA256=68163666575518c213a6593850099adce3863b340ca2751103dbd1f253664e05
  )
endif()
FetchContent_MakeAvailable(mimalloc_src)

add_executable(mimalloc_mre main.cpp plugin.cpp)
target_link_libraries(mimalloc_mre PRIVATE mimalloc-static)
