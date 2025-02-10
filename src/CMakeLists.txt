# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(stockfish_chess_engine VERSION 0.0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")
set(NNUE_NAME nn-5af11540bbfe.nnue)

add_library(stockfish_chess_engine SHARED
  "stockfish_chess_engine.cpp"
  "fixes/stream_fix.cpp"
  "fixes/small_fixes.cpp"
  ${cppPaths}
)

set_target_properties(stockfish_chess_engine PROPERTIES
  PUBLIC_HEADER stockfish_chess_engine.h
  OUTPUT_NAME "stockfish_chess_engine"
)

target_compile_options(stockfish_chess_engine PRIVATE -fPIC)

if(MSVC)
    add_definitions(/FI"fixes/fixes.h")
else()
    add_definitions(-include "fixes/fixes.h")
endif()

target_compile_definitions(stockfish_chess_engine PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(stockfish_chess_engine PRIVATE "-Wl,-z,max-page-size=16384")
endif()

target_include_directories(stockfish_chess_engine
  PUBLIC
  "./"
)

if (MSVC)
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME})
    file(COPY ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME} DESTINATION ${CMAKE_BINARY_DIR}/runner/Release)
else ()
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/${NNUE_NAME})
endif ()
