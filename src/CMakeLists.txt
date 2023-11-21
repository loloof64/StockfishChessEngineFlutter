# Taken from https://github.com/jusax23/flutter_stockfish_plugin

# The Flutter tooling requires that developers have CMake 3.18 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.18)

project(stockfish VERSION 0.0.1 LANGUAGES CXX)
file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")
set(CMAKE_CXX_STANDARD 17)

if(MSVC)
  set(COMMON_FLAGS "/std:c++17 /LTCG")

  set(SIMD_FLAGS "/arch:AVX2 /arch:SSE /DUSE_POPCNT /DUSE_SSE41 /DUSE_SSSE3 /DUSE_SSE2")

  if (CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(STATUS "Adding x86_64 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${SIMD_FLAGS}")
  elseif(CMAKE_SIZEOF_VOID_P EQUAL 4)
    message(STATUS "Adding x86 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${SIMD_FLAGS}")
  endif()

    set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} /Od /Zi")

    set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} /Ox /DNDEBUG")

else()
  set(COMMON_FLAGS "-Wall -Wcast-qual -fno-exceptions -std=c++17 -pedantic -Wextra -Wshadow -Wmissing-declarations -flto -DUSE_PTHREADS") 

  set(SIMD_FLAGS "-msse -msse3 -mpopcnt -DUSE_POPCNT -DUSE_SSE41 -msse4.1 -DUSE_SSSE3 -mssse3 -DUSE_SSE2 -msse2")

  if (CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64")
    message(STATUS "Adding x86_64 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${SIMD_FLAGS} -m64 -DIS_64BIT -DUSE_PTHREADS")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "x86")
    message(STATUS "Adding x86 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} ${SIMD_FLAGS}")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv8")
    message(STATUS "Adding armv8 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} -DIS_64BIT -DUSE_POPCNT -DUSE_NEON=8")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "armv7")
    message(STATUS "Adding armv7 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS}")
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
    message(STATUS "Adding aarch64 specific flags")
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${COMMON_FLAGS} -DIS_64BIT -DNO_PREFETCH")
  endif()

  set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -O0 -g")

  set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE} -O3 -DNDEBUG")
endif()


set(NNUE_NAME nn-5af11540bbfe.nnue)

add_library(stockfish SHARED
  "stockfish.cpp"
  "stream_fix.cpp"
  "small_fixes.cpp"
  ${cppPaths}
)

set_target_properties(stockfish PROPERTIES
  PUBLIC_HEADER stockfish.h
  OUTPUT_NAME "stockfish"
)

if(MSVC)
    add_definitions(/FI"fixes.h")
else()
    add_definitions(-include fixes.h)
endif()

target_compile_definitions(stockfish PUBLIC DART_SHARED_LIB)

target_include_directories(stockfish
  PUBLIC
  "./"
)


if (MSVC)
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME})
    file(COPY ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME} DESTINATION ${CMAKE_BINARY_DIR}/runner/Release)
else ()
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/${NNUE_NAME})
endif ()