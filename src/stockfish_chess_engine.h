// #define _ffigen

#if _WIN32
#include <windows.h>
#include <stddef.h>
typedef ptrdiff_t ssize_t; 
#else
#include <sys/types.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif

#ifndef _ffigen
extern "C" {
#endif

#if defined(_WIN32)
    #define API_EXPORT
#else
    #define API_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

// Stockfish main loop.
API_EXPORT FFI_PLUGIN_EXPORT int stockfish_main();

// Writing to Stockfish STDIN.
API_EXPORT FFI_PLUGIN_EXPORT ssize_t stockfish_stdin_write(char *data);

// Reading Stockfish STDOUT.
API_EXPORT FFI_PLUGIN_EXPORT char * stockfish_stdout_read();

// Reading Stockfish STDERR.
API_EXPORT FFI_PLUGIN_EXPORT char * stockfish_stderr_read();

#ifndef _ffigen
}
#endif