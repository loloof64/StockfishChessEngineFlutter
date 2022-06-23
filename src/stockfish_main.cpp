#include <iostream>
#include <sstream>

#include "Stockfish/src/bitboard.h"
#include "Stockfish/src/endgame.h"
#include "Stockfish/src/position.h"
#include "Stockfish/src/psqt.h"
#include "Stockfish/src/search.h"
#include "Stockfish/src/syzygy/tbprobe.h"
#include "Stockfish/src/thread.h"
#include "Stockfish/src/tt.h"
#include "Stockfish/src/uci.h"
#include "stockfish_main.h"

// FEN string of the initial position, normal chess
const char* StartFEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1";

// Code taken from Stockfish's sources : main.cpp
void main_init() {
  using namespace Stockfish;

  int argc = 1;
  char *argv[] = {(char *) ""};

  std::cout << engine_info() << std::endl;

  CommandLine::init(argc, argv);
  UCI::init(Options);
  Tune::init();
  PSQT::init();
  Bitboards::init();
  Position::init();
  Bitbases::init();
  Endgames::init();
  Threads.set(size_t(Options["Threads"]));
  Search::clear(); // After threads are up
  Eval::NNUE::init();
}

// Code adapted from Stockfish's sources : uci.cpp
void processCommand(std::string command) {
  using namespace Stockfish;
  using namespace UCI;
  using namespace std;
  
  Position pos;
  string token;
  StateListPtr states(new std::deque<StateInfo>(1));

  pos.set(StartFEN, false, &states->back(), Threads.main());

      istringstream is(command);
      is >> skipws >> token;

      /////////////////////////////////////////////////////////
      sync_cout << "Token is " << token << sync_endl;
      /////////////////////////////////////////////////////////

      if (    token == "quit"
          ||  token == "stop")
          Threads.stop = true;

      // The GUI sends 'ponderhit' to tell us the user has played the expected move.
      // So 'ponderhit' will be sent if we were told to ponder on the same move the
      // user has played. We should continue searching but switch from pondering to
      // normal search.
      else if (token == "ponderhit")
          Threads.main()->ponder = false; // Switch to normal search

      else if (token == "uci")
          sync_cout << "id name " << engine_info(true)
                    << "\n"       << Options
                    << "\nuciok"  << sync_endl;

      else if (token == "setoption")  UCI::setoption(is);
      else if (token == "go")         UCI::go(pos, is, states);
      else if (token == "position")   UCI::position(pos, is, states);
      else if (token == "ucinewgame") Search::clear();
      else if (token == "isready")    sync_cout << "readyok" << sync_endl;

      // Additional custom non-UCI commands, mainly for debugging.
      // Do not use these commands during a search!
      else if (token == "flip")     pos.flip();
      else if (token == "bench")    UCI::bench(pos, is, states);
      else if (token == "d")        sync_cout << pos << sync_endl;
      else if (token == "eval")     UCI::trace_eval(pos);
      else if (token == "compiler") sync_cout << compiler_info() << sync_endl;
      else if (token == "export_net")
      {
          std::optional<std::string> filename;
          std::string f;
          if (is >> skipws >> f)
              filename = f;
          Eval::NNUE::save_eval(filename);
      }
      else if (!token.empty() && token[0] != '#')
          sync_cout << "Unknown command: " << command << sync_endl;
}

// Code taken from Stockfish's sources : main.cpp
void main_end() {
  using namespace Stockfish;

  Threads.set(0);
}