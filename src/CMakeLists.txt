# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(stockfish_chess_engine_library VERSION 0.0.1 LANGUAGES C)

add_library(stockfish_chess_engine SHARED
  "stockfish_chess_engine.c"
)

set_target_properties(stockfish_chess_engine PROPERTIES
  PUBLIC_HEADER stockfish_chess_engine.h
  OUTPUT_NAME "stockfish_chess_engine"
)

target_compile_definitions(stockfish_chess_engine PUBLIC DART_SHARED_LIB)
