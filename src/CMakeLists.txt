# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

project(stockfish_chess_engine_library VERSION 0.0.1 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)

file(GLOB_RECURSE cppPaths "Stockfish/src/*.cpp")
set(NNUE_NAME nn-5af11540bbfe.nnue)

add_library(loloof64_stockfish SHARED
  "stockfish_chess_engine.cpp"
  "stream_fix.cpp"
  "small_fixes.cpp"
  ${cppPaths}
)

set_target_properties(loloof64_stockfish PROPERTIES
  PUBLIC_HEADER stockfish_chess_engine.h
  OUTPUT_NAME "loloof64_stockfish"
)

if(MSVC)
    add_definitions(/FI"fixes.h")
else()
    add_definitions(-include fixes.h)
endif()

target_compile_definitions(loloof64_stockfish PUBLIC DART_SHARED_LIB)

if (ANDROID)
  # Support Android 15 16k page size
  target_link_options(loloof64_stockfish PRIVATE "-Wl,-z,max-page-size=16384")
endif()

target_include_directories(loloof64_stockfish
  PUBLIC
  "./"
)

if (MSVC)
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME})
    file(COPY ${CMAKE_BINARY_DIR}/runner/Debug/${NNUE_NAME} DESTINATION ${CMAKE_BINARY_DIR}/runner/Release)
else ()
    file(DOWNLOAD https://tests.stockfishchess.org/api/nn/${NNUE_NAME} ${CMAKE_BINARY_DIR}/${NNUE_NAME})
endif ()
