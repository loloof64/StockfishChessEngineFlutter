// #define _ffigen

#if _WIN32
#include <windows.h>
#include <BaseTsd.h>    
#else
#include <sys/types.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

// Stockfish main loop.
#ifndef _ffigen
extern "C"
#endif
FFI_PLUGIN_EXPORT int stockfish_main();

// Writing to Stockfish STDIN.
#ifndef _ffigen
extern "C"
#endif
FFI_PLUGIN_EXPORT ssize_t stockfish_stdin_write(char *data);

// Reading Stockfish STDOUT.
#ifndef _ffigen
extern "C"
#endif
FFI_PLUGIN_EXPORT char * stockfish_stdout_read();