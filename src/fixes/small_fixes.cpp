// Taken from https://github.com/jusax23/flutter_stockfish_plugin

#include "small_fixes.h"

#include <cstring>
#include <iostream>
#include <string>

#ifdef _WIN32
#include <windows.h>
#endif

#ifdef _WIN32
#ifdef _MSC_VER


bool fake_get_pgmptr(char** ptr) {
    wchar_t buffer[MAX_PATH];
    if (GetModuleFileNameW(nullptr, buffer, MAX_PATH) != 0) {
        char* narrowBuffer = new char[MAX_PATH];
        WideCharToMultiByte(CP_UTF8, 0, buffer, -1, narrowBuffer, MAX_PATH,
                            NULL, NULL);
        *ptr = narrowBuffer;
        return false;
    }
    return true;
}
#endif
#endif