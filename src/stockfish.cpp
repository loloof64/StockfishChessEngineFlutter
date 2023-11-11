#include "stockfish.h"

#include <thread>
#include <chrono>
#include <optional>

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
  using namespace std::chrono_literals;
  std::optional<std::string> output;

  while (true) {
    output = CommandsQueue::getInstance().receive_command_output();
    if (output.has_value()) {
      break;
    }
    std::this_thread::sleep_for(100ms);
  }

  auto output_str = output.value().c_str();
  strncpy(RESULT, output_str, MAX_SIZE);
  return RESULT;
}