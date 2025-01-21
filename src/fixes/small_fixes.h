// Taken from https://github.com/jusax23/flutter_stockfish_plugin

#ifndef _SMALL_FIXES_H_
#define _SMALL_FIXES_H_

#ifdef _WIN32
#ifdef _MSC_VER

// Expects a pointer to a char pointer.
// Overwrites *ptr with a new allocated memory. 
// Memory managment is left to the user of this function.
bool fake_get_pgmptr(char** ptr);
#endif
#endif

#endif