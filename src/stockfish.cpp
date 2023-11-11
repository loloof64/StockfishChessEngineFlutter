#include "stockfish.h"

#include "Stockfish/src/bitboard.h"
#include "Stockfish/src/endgame.h"
#include "Stockfish/src/position.h"
#include "Stockfish/src/search.h"
#include "Stockfish/src/thread.h"
#include "Stockfish/src/tt.h"
#include "Stockfish/src/uci.h"
#include "Stockfish/src/syzygy/tbprobe.h"

#include "commands_queue.h"

#define MAX_SIZE 200

int main(int, char **);

const char *QUITOK = "quitok\n";
const char EMPTY[] = {'\0'};
char RESULT[MAX_SIZE+1];

int stockfish_main()
{
  int argc = 1;
  char *argv[] = {(char *) ""};
  int exitCode = main(argc, argv);

  CommandsQueue::getInstance().send_command_input(QUITOK);

  return exitCode;
}

void stockfish_stdin_write(char *command)
{
  CommandsQueue::getInstance().send_command_input(std::string(command));
}

const char *stockfish_stdout_read()
{
  auto wrapped_output = CommandsQueue::getInstance().receive_command_output();
  if (wrapped_output.has_value()) {
    auto output_str = wrapped_output.value().c_str();
    strncpy(RESULT, output_str, MAX_SIZE);
    return RESULT;
  }
  else {
    return EMPTY;
  }
}