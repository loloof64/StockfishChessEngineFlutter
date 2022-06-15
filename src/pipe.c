#include "pipe.h"
#include "handleapi.h"

int pipe(int pipefd[2]) {
    int hPipe;
    
    hPipe = CreatePipe(pipefd[0], pipefd[1], 1024);
    return hPipe;
}