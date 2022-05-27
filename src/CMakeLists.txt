# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(stockfish VERSION 0.0.1 LANGUAGES CPP)
file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")

add_library(stockfish SHARED
  "stockfish_chess_engine.cpp"
  ${cppPaths}
)

set_target_properties(stockfish PROPERTIES
  PUBLIC_HEADER stockfish_chess_engine.h
  OUTPUT_NAME "stockfish"
)

target_compile_definitions(stockfish PUBLIC DART_SHARED_LIB)

file(DOWNLOAD https://tests.stockfishchess.org/api/nn/nn-3c0aa92af1da.nnue ${CMAKE_BINARY_DIR}/nn-3c0aa92af1da.nnue)
