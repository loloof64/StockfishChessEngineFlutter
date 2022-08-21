# The Flutter tooling requires that developers have CMake 3.18 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.18)

project(stockfish VERSION 0.0.1 LANGUAGES CXX)
file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")
set(CMAKE_CXX_STANDARD 17)
set(NNUE_NAME nn-ad9b42354671.nnue)

add_library(stockfish SHARED
  "stockfish.cpp"
  ${cppPaths}
)

set_target_properties(stockfish PROPERTIES
  PUBLIC_HEADER stockfish.h
  OUTPUT_NAME "stockfish"
)

target_compile_definitions(stockfish PUBLIC DART_SHARED_LIB)

if (MSVC)
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME})
    file(COPY ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME} DESTINATION ${CMAKE_BINARY_DIR}/runner/Release)
else ()
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/${NNUE_NAME})
endif ()
