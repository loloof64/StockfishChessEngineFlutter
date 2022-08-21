#include <iostream>
#include <cstdio>
#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#define STDIN_FILENO 0
#define STDOUT_FILENO 1
#define STDERR_FILENO 2
#ifdef _WIN64
#define ssize_t __int64
#else
#define ssize_t long
#endif
#else
#include <unistd.h>
#endif

#include "stockfish.h"

#include "Stockfish/src/bitboard.h"
#include "Stockfish/src/endgame.h"
#include "Stockfish/src/position.h"
#include "Stockfish/src/search.h"
#include "Stockfish/src/thread.h"
#include "Stockfish/src/tt.h"
#include "Stockfish/src/uci.h"
#include "Stockfish/src/syzygy/tbprobe.h"

// https://jineshkj.wordpress.com/2006/12/22/how-to-capture-stdin-stdout-and-stderr-of-child-program/
#define NUM_PIPES 2
#define PARENT_WRITE_PIPE 0
#define PARENT_READ_PIPE 1
#define READ_FD 0
#define WRITE_FD 1
#define PARENT_READ_FD (pipes[PARENT_READ_PIPE][READ_FD])
#define PARENT_WRITE_FD (pipes[PARENT_WRITE_PIPE][WRITE_FD])
#define CHILD_READ_FD (pipes[PARENT_WRITE_PIPE][READ_FD])
#define CHILD_WRITE_FD (pipes[PARENT_READ_PIPE][WRITE_FD])

#define BUFFER_SIZE 100

int main(int, char **);

const char *QUITOK = "quitok\n";
int pipes[NUM_PIPES][2];
char buffer[BUFFER_SIZE+1];

int stockfish_init()
{
  #ifdef _WIN32
  unsigned int pipeSize = BUFFER_SIZE;
  int textMode = _O_TEXT;
  _pipe(pipes[PARENT_READ_PIPE], pipeSize, textMode);
  _pipe(pipes[PARENT_WRITE_PIPE], pipeSize, textMode);
  #else
  pipe(pipes[PARENT_READ_PIPE]);
  pipe(pipes[PARENT_WRITE_PIPE]);
  #endif

  return 0;
}

int stockfish_main()
{
  #ifdef _WIN32
  _dup2(CHILD_READ_FD, STDIN_FILENO);
  _dup2(CHILD_WRITE_FD, STDOUT_FILENO);
  #else
  dup2(CHILD_READ_FD, STDIN_FILENO);
  dup2(CHILD_WRITE_FD, STDOUT_FILENO);
  #endif

  int argc = 1;
  char *argv[] = {(char *) ""};
  int exitCode = main(argc, argv);

  std::cout << QUITOK << std::flush;

  return exitCode;
}

ssize_t stockfish_stdin_write(char *data)
{
  #ifdef _WIN32
  return _write(PARENT_WRITE_FD, data, strlen(data));
  #else
  return write(PARENT_WRITE_FD, data, strlen(data));
  #endif
}

char *stockfish_stdout_read()
{
  #ifdef _WIN32
  ssize_t count = _read(PARENT_READ_FD, buffer, sizeof(buffer) - 1);
  #else
  ssize_t count = read(PARENT_READ_FD, buffer, sizeof(buffer) - 1);
  #endif
  
  if (count < 0)
  {
    return NULL;
  }

  buffer[count] = 0;
  if (strcmp(buffer, QUITOK) == 0)
  {
    return NULL;
  }

  return buffer;
}