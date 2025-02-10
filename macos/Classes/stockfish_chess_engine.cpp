#include "stockfish_chess_engine.h"

#include "fixes/fixes.h"
#include <string>

#include "Stockfish/src/main.h"

#define BUFFER_SIZE 1024

const char *QUITOK = "quit\n";

int main(int, char **);

std::string data;
std::string errData;
char buffer[BUFFER_SIZE + 1];
char errBuffer[BUFFER_SIZE + 1];

FFI_PLUGIN_EXPORT int stockfish_main() {
  int argc = 1;
  char *argv[] = {(char *)""};
  int exitCode = main(argc, argv);

  fakeout << QUITOK << "\n";

#if _WIN32
  Sleep(100);
#else
  usleep(100);
#endif

  fakeout.close();
  fakein.close();

  return exitCode;
}

FFI_PLUGIN_EXPORT ssize_t stockfish_stdin_write(char *data) {
  std::string val(data);
  fakein << val << fakeendl;
  return val.length();
}

FFI_PLUGIN_EXPORT char* stockfish_stdout_read() {
  if (getline(fakeout, data)) {
    size_t len = data.length();
    size_t i;
    for (i = 0; i < len && i < BUFFER_SIZE; i++) {
      buffer[i] = data[i];
    }
    buffer[i] = 0;
    return buffer;
  }
  return nullptr;
}

FFI_PLUGIN_EXPORT char* stockfish_stderr_read() {
  if (getline(fakeerr, errData)) {
    size_t len = errData.length();
    size_t i;
    for (i = 0; i < len && i < BUFFER_SIZE; i++) {
      errBuffer[i] = errData[i];
    }
    errBuffer[i] = 0;
    return errBuffer;
  }
  return nullptr;
}